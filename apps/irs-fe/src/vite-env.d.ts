/// <reference types="vite/client" />

interface Window {
  __RUNTIME_CONFIG__?: {
    VITE_API_BASE_URL?: string;
    [key: string]: string | undefined;
  };
}
