# Development Environment

Install these:

- XCode
- [RubyMotion](http://www.rubymotion.com/developer-center/guides/getting-started/)
- [CocoaPods](http://cocoapods.org/): `gem install cocoapods && pod setup`
- [Homebrew]
- `brew install npm`
- `npm install`
- `bundle install`

Download the TestFlight SDK into `./vendor`. It should be called `./vendor/TestFlight`:

    $ grep -q '## 2.0.2' vendor/TestFlight/release_notes.md && echo 'TestFlight found'
    TestFlight found

Download the Pixate SDK into `./vendor`. It should be called `./vendor/Pixate.framework`:

    $ [[ -d vendor/Pixate.framework/Versions/1.1 ]] && echo 'Pixate found'
    Pixate found

Set these environment variables:

- `TF_APP_TOKEN` = the TestFlight app token

# Adding a User
1. Invite the user to TestFlight. TestFlight will collect their UDID.
2. Sign into the iOS developer center. Add the user's UDID to the [device list](https://developer.apple.com/account/ios/device/deviceList.action).
3. In the [Provisioning Profiles tab](https://developer.apple.com/account/ios/profile/profileList.action), edit the iOS Team Provisioning Profile. Add the new UDID.
4. Download and install the modified provisioning profile.
5. Use the iPhone Configuration Utility to remove the old provisioning profiles from your computer.
6. Use XCode (app) Organizer (window) “Provisioning Profiles” (sidebar item) to remove the old provisioning profiles from your devices.

# Uploading a Build
1. `rake archive:distribution`
2. Upload the IPA from `./build/iPhoneOS-7.0-Release` to the [Testflight upload page](https://testflightapp.com/dashboard/builds/add/).
3. If the provisioning profile changed it from from `~/Library/MobileDevice/'Provisioning Profiles'`.

# App Store Release Checklist
1. Remove the call to `UIDevice.currentDevice.uniqueIdentifier` from `./app/app_delegate.rb`.
There may be something to replace this by then; check on TestFlight.