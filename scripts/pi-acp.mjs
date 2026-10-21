// pi-acp embeds the Pi SDK without the CLI's HTTP proxy initialization.
// Reuse its installed Pi dispatcher before loading the ACP entry point.
import { realpathSync } from "node:fs";
import { pathToFileURL } from "node:url";

const entry = process.argv[2];
if (!entry) {
    throw new Error("Usage: node pi-acp.mjs <path-to-pi-acp>");
}

const entryUrl = pathToFileURL(realpathSync(entry));
const dispatcherUrl = new URL(
    "../node_modules/@earendil-works/pi-coding-agent/dist/core/http-dispatcher.js",
    entryUrl,
);
const { configureHttpDispatcher } = await import(dispatcherUrl.href);
configureHttpDispatcher();

process.argv = [process.argv[0], entryUrl.pathname, ...process.argv.slice(3)];
await import(entryUrl.href);
