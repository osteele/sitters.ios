[![Code Climate](https://codeclimate.com/repos/5290f2d67e00a43c5d053345/badges/923265ce69ba80f69de3/gpa.png)](https://codeclimate.com/repos/5290f2d67e00a43c5d053345/feed)

# Getting Started

Install these:

* Install XCode [from the App Store](https://itunes.apple.com/us/app/xcode/id497799835)
* Install the XCode command line tools: enter `gcc -v` in the terminal and press the `Install` button in the dialog. If gcc instead prints version information, the XCode command line line tools are already installed.
* Download and install [RubyMotion](http://www.rubymotion.com/developer-center/guides/getting-started/)
* Install [CocoaPods](http://cocoapods.org/): `gem install cocoapods && pod setup`
* Install [Homebrew](http://brew.sh)
* `brew install git node postgresql rbenv ruby ruby-build`
* `npm install`
* `bundle install`
* `rake pod:install`

Copy `./.env.template` to `./.env` and edit in the required values.


# Building and Running

Run on the simulator: `rake`

Run on a USB-attached device: `rake device`


# API Documentation

`yard` builds the documentation into`./build/doc`.
Open `./build/doc/index.html` in a browser to view the documentation.


# Coding Standards

* Indent with spaces, two per indentation level.
* Use PascalCase for class names; camelCase for method and variable names. (This is the same as Objective C.)
* Used ClassName:ConstantName or ModuleName:ConstantName for constants and other globals that pertain to a class or module.
* A file that defines ThisClass should be named this_class.rb.
* Use [TomDoc](http://tomdoc.org) documentation standards.


# Adding a User
1. Invite the user to TestFlight. TestFlight will collect their UDID.
2. Sign into the iOS developer center. Add the user's UDID to the [device list](https://developer.apple.com/account/ios/device/deviceList.action).
3. In the [Provisioning Profiles tab](https://developer.apple.com/account/ios/profile/profileList.action), edit the iOS Team Provisioning Profile. Add the new UDID.
4. Download and install the modified provisioning profile.
5. Edit the value of `IOS_APP_7S_PRODUCTION_PROFILE_ID` in `~/.env`.


# Distributing via TestFlight
1. `rake testflight:upload`
2. If the provisioning profile changed, upload the new profile from `~/Library/MobileDevice/'Provisioning Profiles'`.
`rake profiles:open` will open this folder.
3. Open the TestFlight build page and add users.


# App Store Release Checklist
1. Remove the call to `UIDevice.currentDevice.uniqueIdentifier` from `./app/app_delegate.rb`.
There may be something to replace this by then; check on TestFlight.
2. Add acknowledgements for third-party software.
