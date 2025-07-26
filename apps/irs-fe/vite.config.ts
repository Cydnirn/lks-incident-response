import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import runtimeEnv from 'vite-plugin-runtime-env'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    runtimeEnv({
      // Configure which environment variables should be available at runtime
      // VITE_API_BASE_URL will be replaced at runtime
    }),
  ],
})
