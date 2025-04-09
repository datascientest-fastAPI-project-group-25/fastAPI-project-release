/// <reference types="bun-types" />

declare module "bun" {
    interface SpawnOptions {
        cwd?: string;
        env?: Record<string, string | undefined>;
        stdin?: 'inherit' | 'pipe' | number;
        stdout?: 'inherit' | 'pipe' | number;
        stderr?: 'inherit' | 'pipe' | number;
    }

    interface SubprocessResult {
        stdout: ReadableStream;
        stderr: ReadableStream;
        exitCode: number | null;
    }

    export const spawn: (command: string[] | string, options?: SpawnOptions) => SubprocessResult;
    export const which: (command: string) => string | null;
    export const argv: string[];
    export const stdin: { file: any, stream: () => AsyncIterableIterator<Uint8Array> };
}

declare interface ImportMeta {
    /**
     * `true` if the current module is the entry point.
     */
    main?: boolean;
    url: string;
}