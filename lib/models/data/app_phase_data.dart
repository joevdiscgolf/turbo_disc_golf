enum AppPhase {
  loading, // app is booting + checking services
  home, // main app
  loggedOut, // no user
  onboarding, // user logged in but missing onboarding
}
