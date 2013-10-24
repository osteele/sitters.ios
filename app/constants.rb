# Conversion factors from the Keynote design deck to iOS resolution.
# These allow the numbers in the Keynote inspector to be used as constants below.
KeynoteShadowOffsetRatio = 0.5
KeynoteShadowRadiusRatio = 0.25

# RubyMotion 2.11 doesn't implement these
NSNumberFormatterSpellOutStyle = 5 unless Object.const_defined?(:NSNumberFormatterSpellOutStyle)
UIFontDescriptorTraitBold = 1 << 1 unless Object.const_defined?(:UIFontDescriptorTraitBold)
