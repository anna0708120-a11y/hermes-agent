declare global {
  interface Window {
    /**
     * Injected by the server before the dashboard bundle loads. It controls
     * whether the embedded TUI Chat surface is available for this deployment.
     */
    __HERMES_DASHBOARD_EMBEDDED_CHAT__?: boolean;
  }
}

/**
 * Whether the dashboard's embedded TUI Chat surface is available.
 *
 * The server defaults this feature to enabled. Hosted management deployments
 * can set HERMES_WEB_ONLY=1, which injects false and prevents the SPA from
 * mounting the PTY-backed Chat route.
 */
export function isDashboardEmbeddedChatEnabled(): boolean {
  return window.__HERMES_DASHBOARD_EMBEDDED_CHAT__ !== false;
}
