# CopyPop visual system

CopyPop is a small Windows utility, not a dashboard. Its central interaction is selectable text and a real copy response. The settings window uses a stable 216 logical pixel navigation rail, left-aligned content, 32 pixel content gutters, and a scrollable form. Welcome is a compact 610×660 window with a draggable, rounded frame.

Tokens: paper `#f5f7fb`, rail `#edf1f7`, surface `#ffffff`, ink `#202d43`, secondary ink `#596b83`, ocean `#315fb2`. Dark theme maps these to `#171c25`, `#1d2430`, `#222b38`, `#ecf1fa`, `#acb9cc`, `#8fb6ff` respectively. The animated ink defaults to `#5989e8`; it is independent of the UI accent.

Typography uses the Windows Segoe UI Variable / Segoe UI family with Microsoft YaHei UI for Chinese. Form text is 14px, descriptions 12px, page headings 28px. Buttons use 13px Chinese UI typography. Sizes are logical pixels and scale through Qt.

The skill search matched Minimalism & Swiss Style; its marketing hero, gold palette and web typography recommendations do not fit this desktop utility and were replaced with the product-specific structure above. Motion belongs primarily to copied text. Normal controls use short, interruptible feedback. Lucide 0.468.0 supplies the small set of packaged outline icons.

Keyboard controls use Qt Quick Controls semantics and visible focus. The preview measures the actual selected sample positions and uses the same EffectLayer as the native overlay. No account or network surface exists.
