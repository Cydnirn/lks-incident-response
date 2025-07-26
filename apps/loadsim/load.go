package main

import (
	"context"
	"log"
	"runtime"
	"sync/atomic"
	"time"
	"runtime/debug"

	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/mem"
)

// runLoad starts the load generation based on the provided settings
func runLoad(ctx context.Context, loadSettings LoadSettings) {
	log.Printf("Starting load generation: CPU=%d%%, Memory=%.2fGB, Duration=%ds", 
		loadSettings.CPULoadPercent, loadSettings.MemoryGB, loadSettings.DurationSec)

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
	if loadSettings.MemoryGB > 0 {
		go generateMemoryLoad(loadCtx, loadSettings.MemoryGB)
	}

	// Wait for context cancellation
	<-loadCtx.Done()

	// Clean up
	log.Println("Cleaning up load generation...")
	atomic.StoreInt32(&cpuLoadActive, 0)
	
	statusMutex.Lock()
	status.Running = false
	status.CPULoadPercent = 0
	status.MemoryGB = 0
	memoryBlocks = nil
	statusMutex.Unlock()

	log.Println("Load generation stopped")
}

// generateCPULoad creates CPU load by running busy loops
func generateCPULoad(ctx context.Context, targetPercent int) {
	numCPU := runtime.NumCPU()
	atomic.StoreInt32(&cpuLoadActive, 1)

	log.Printf("Starting CPU load generation on %d cores, target: %d%%", numCPU, targetPercent)

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
func generateMemoryLoad(ctx context.Context, targetGB float64) {
	log.Printf("Starting memory load generation, target: %.2fGB", targetGB)

	// Convert GB to bytes
	targetBytes := int64(targetGB * 1024 * 1024 * 1024)
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

	log.Printf("Memory allocation completed: %.2fGB", float64(totalAllocated)/1024/1024/1024)

	// Keep the memory allocated until context is cancelled
	<-ctx.Done()

	// Clean up memory
	statusMutex.Lock()
	memoryBlocks = nil
	statusMutex.Unlock()

	runtime.GC()
	debug.FreeOSMemory()

	log.Println("Memory load generation stopped")
}

// updateSystemStatus updates the current system status information
func updateSystemStatus() {
	// Get CPU usage
	cpuPercent, err := cpu.Percent(time.Second, false)
	if err == nil && len(cpuPercent) > 0 {
		// CPU percentage is already calculated by gopsutil
	}

	// Get memory usage
	_, err = mem.VirtualMemory()
	if err == nil {
		// Memory usage percentage and used memory are available
		// The actual system metrics are used directly in the handlers
	}

	// Note: The actual system metrics are used in the handlers
	// This function can be extended to store these values if needed
}
