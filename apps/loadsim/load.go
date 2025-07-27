package main

import (
	"context"
	"runtime"
	"runtime/debug"
	"sync/atomic"
	"time"

	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/mem"
)

// runLoad starts the load generation based on the provided settings
func runLoad(ctx context.Context, loadSettings LoadSettings) {
	logInfo("Starting load generation", map[string]interface{}{
		"cpu_load_percent": loadSettings.CPULoadPercent,
		"memory_mb":        loadSettings.MemoryMB,
		"duration_sec":     loadSettings.DurationSec,
	})

	// Create a context with timeout if duration is specified
	var loadCtx context.Context
	var loadCancel context.CancelFunc

	if loadSettings.DurationSec > 0 {
		loadCtx, loadCancel = context.WithTimeout(ctx, time.Duration(loadSettings.DurationSec)*time.Second)
		defer loadCancel()
	} else {
		loadCtx = ctx
	}

	// Start CPU load generation if specified
	if loadSettings.CPULoadPercent > 0 {
		go generateCPULoad(loadCtx, loadSettings.CPULoadPercent)
	}

	// Start memory load generation if specified
	if loadSettings.MemoryMB > 0 {
		go generateMemoryLoad(loadCtx, loadSettings.MemoryMB)
	}

	// Wait for context cancellation
	<-loadCtx.Done()

	// Clean up
	logInfo("Cleaning up load generation", nil)
	atomic.StoreInt32(&cpuLoadActive, 0)

	statusMutex.Lock()
	status.Running = false
	status.CPULoadPercent = 0
	status.MemoryMB = 0
	memoryBlocks = nil
	statusMutex.Unlock()

	logInfo("Load generation stopped", nil)
}

// generateCPULoad creates CPU load by running busy loops
func generateCPULoad(ctx context.Context, targetPercent int) {
	numCPU := runtime.NumCPU()
	atomic.StoreInt32(&cpuLoadActive, 1)

	logInfo("Starting CPU load generation", map[string]interface{}{
		"num_cores":      numCPU,
		"target_percent": targetPercent,
	})

	// Start a goroutine for each CPU core
	for i := 0; i < numCPU; i++ {
		go func(coreID int) {
			// Calculate work and sleep durations based on target percentage
			workDuration := time.Duration(targetPercent) * time.Millisecond
			sleepDuration := time.Duration(100-targetPercent) * time.Millisecond

			for {
				select {
				case <-ctx.Done():
					return
				default:
					if atomic.LoadInt32(&cpuLoadActive) == 0 {
						return
					}

					// Busy work
					start := time.Now()
					for time.Since(start) < workDuration {
						// Perform some CPU-intensive work
						for j := 0; j < 1000; j++ {
							_ = j * j
						}
					}

					// Sleep to control CPU usage
					if sleepDuration > 0 {
						time.Sleep(sleepDuration)
					}
				}
			}
		}(i)
	}
}

// generateMemoryLoad allocates memory to simulate memory load
func generateMemoryLoad(ctx context.Context, targetMB int) {
	logInfo("Starting memory load generation", map[string]interface{}{
		"target_mb": targetMB,
	})

	// Convert MB to bytes
	targetBytes := int64(targetMB * 1024 * 1024)
	blockSize := int64(1024 * 1024) // 1MB blocks

	statusMutex.Lock()
	memoryBlocks = nil // Clear existing blocks
	statusMutex.Unlock()

	// Allocate memory in chunks
	var totalAllocated int64
	for totalAllocated < targetBytes {
		select {
		case <-ctx.Done():
			return
		default:
			// Calculate remaining bytes to allocate
			remaining := targetBytes - totalAllocated
			currentBlockSize := blockSize
			if remaining < blockSize {
				currentBlockSize = remaining
			}

			// Allocate memory block
			block := make([]byte, currentBlockSize)

			// Write to the memory to ensure it's actually allocated
			for i := range block {
				block[i] = byte(i % 256)
			}

			statusMutex.Lock()
			memoryBlocks = append(memoryBlocks, block)
			statusMutex.Unlock()

			totalAllocated += currentBlockSize

			// Small delay to prevent overwhelming the system
			time.Sleep(10 * time.Millisecond)
		}
	}

	logInfo("Memory allocation completed", map[string]interface{}{
		"allocated_mb": totalAllocated / 1024 / 1024,
	})

	// Keep the memory allocated until context is cancelled
	<-ctx.Done()

	// Clean up memory
	statusMutex.Lock()
	memoryBlocks = nil
	statusMutex.Unlock()

	runtime.GC()
	debug.FreeOSMemory()

	logInfo("Memory load generation stopped", nil)
}

// updateSystemStatus updates the current system status information
func updateSystemStatus() {
	// Get CPU usage
	cpuPercent, err := cpu.Percent(time.Second, false)
	if err != nil {
		logError("Failed to get CPU usage", err, 500)
		return
	}

	if len(cpuPercent) > 0 {
		logDebug("CPU usage updated", map[string]interface{}{
			"cpu_percent": cpuPercent[0],
		})
	}

	// Get memory usage
	vmStat, err := mem.VirtualMemory()
	if err != nil {
		logError("Failed to get memory usage", err, 500)
		return
	}

	logDebug("Memory usage updated", map[string]interface{}{
		"memory_used_percent": vmStat.UsedPercent,
		"memory_total_gb":     float64(vmStat.Total) / 1024 / 1024 / 1024,
	})
}
