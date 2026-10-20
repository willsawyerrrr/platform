// Preloaded with `node --import`: replaces `fetch` with a scripted sequence of responses read
// from `$FETCH_ROUTES` (`[{ expect: "METHOD /path-prefix", status, body }]`), logs requests to
// `$FETCH_LOG`, and skips `setTimeout` delays.
import { appendFileSync, readFileSync } from "node:fs";

const routes = JSON.parse(readFileSync(process.env.FETCH_ROUTES, "utf8"));

globalThis.setTimeout = (callback) => queueMicrotask(callback);
globalThis.fetch = async (url, { method, headers, body }) => {
  const { pathname, search } = new URL(url);
  const request = `${method} ${pathname}${search}`;
  appendFileSync(process.env.FETCH_LOG, `${request} ${headers.Authorization.slice(0, 11)} ${body ?? ""}\n`);
  const route = routes.shift();
  if (!route || !request.startsWith(route.expect)) {
    return new Response(`unexpected request ${request}`, { status: 599 });
  }
  const status = route.status ?? 200;
  return new Response(status === 204 ? null : JSON.stringify(route.body ?? {}), { status });
};
