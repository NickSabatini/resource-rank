import { createHash } from "crypto";

export function canonicalizeUrl(input: string) {
  const url = new URL(input);
  const protocol = url.protocol.toLowerCase();
  const host = url.hostname.toLowerCase();
  const pathname = url.pathname.replace(/\/+$/, "") || "/";

  const sortedParams = new URLSearchParams(url.searchParams);
  sortedParams.sort();

  for (const key of [...sortedParams.keys()]) {
    if (key.startsWith("utm_") || key === "fbclid" || key === "gclid") {
      sortedParams.delete(key);
    }
  }

  const query = sortedParams.toString();
  const canonicalUrl = `${protocol}//${host}${pathname}${query ? `?${query}` : ""}`;
  const canonicalUrlHash = createHash("sha256").update(canonicalUrl).digest("hex");

  return { canonicalUrl, canonicalUrlHash };
}
