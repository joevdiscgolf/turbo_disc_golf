enum AppPhase {
  initial, // app is booting + checking services
  home, // main app
  loggedOut, // no user
  onboarding, // user logged in but missing onboarding
  featureWalkthrough, // user completed onboarding, show feature walkthrough
  forceUpgrade, // force the user to update app
  connectionRequired, // can't load version info, need internet
}
