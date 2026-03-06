/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_CLARITY_PROJECT_ID?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

declare module '*?url' {
  const value: string;
  export default value;
}