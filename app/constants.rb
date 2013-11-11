ISO8601DateFormatterInstance = NSDateFormatter.alloc.init.setDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")

ApplicationDidLoadDataNotification = NSNotification.notificationWithName('ApplicationDidLoadData', object:nil)
ApplicationWillAttemptLoginNotification = NSNotification.notificationWithName('ApplicationWillAttemptLogin', object:nil)
ApplicationDidAttemptLoginNotification = NSNotification.notificationWithName('ApplicationDidAttemptLogin', object:nil)

# Conversion factors from the Keynote design deck to iOS resolution.
# These allow the numbers in the Keynote inspector to be used as constants below.
KeynoteShadowOffsetRatio = 0.5
KeynoteShadowRadiusRatio = 0.25

# RubyMotion 2.11 doesn't define these
NSCachesDirectory = 13 unless Object.const_defined?(:NSCachesDirectory)
NSNumberFormatterSpellOutStyle = 5 unless Object.const_defined?(:NSNumberFormatterSpellOutStyle)
UIFontDescriptorTraitBold = 1 << 1 unless Object.const_defined?(:UIFontDescriptorTraitBold)

EKEntityTypeEvent = 0 unless Object.const_defined?(:EKEntityTypeEvent)
EKAuthorizationStatusNotDetermined = 0
EKAuthorizationStatusRestricted = 1
EKAuthorizationStatusDenied = 2
EKAuthorizationStatusAuthorized = 3
