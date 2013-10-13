# Development Environment

Install these:

- XCode
- [RubyMotion](http://www.rubymotion.com/developer-center/guides/getting-started/)
- [CocoaPods](http://cocoapods.org/): `gem install cocoapods && pod setup`
- [Homebrew]
- `brew install npm`
- `npm install`
- `bundle install`
- `rake pod:install`

Download the TestFlight SDK into `./vendor`. It should be called `./vendor/TestFlight`:

    $ grep -q '## 2.0.2' vendor/TestFlight/release_notes.md && echo 'TestFlight found'
    TestFlight found

Download the Pixate SDK into `./vendor`. It should be called `./vendor/Pixate.framework`:

    $ [[ -d vendor/Pixate.framework/Versions/1.1 ]] && echo 'Pixate found'
    Pixate found

Copy `~/.env.template` to `~/.env` and edit in the token values.


# Adding a User
1. Invite the user to TestFlight. TestFlight will collect their UDID.
2. Sign into the iOS developer center. Add the user's UDID to the [device list](https://developer.apple.com/account/ios/device/deviceList.action).
3. In the [Provisioning Profiles tab](https://developer.apple.com/account/ios/profile/profileList.action), edit the iOS Team Provisioning Profile. Add the new UDID.
4. Download and install the modified provisioning profile.
5. Edit the value of `IOS_APP_7S_PRODUCTION_PROFILE_ID` in `~/.env`.

# Uploading a Build
1. `rake testflight:upload`
2. If the provisioning profile changed it from from `~/Library/MobileDevice/'Provisioning Profiles'`.
3. Open the TestFlight build page and add users.

# App Store Release Checklist
1. Remove the call to `UIDevice.currentDevice.uniqueIdentifier` from `./app/app_delegate.rb`.
There may be something to replace this by then; check on TestFlight.
