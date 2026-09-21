// Legacy alias — CandyButton is now TactileButton
// This file exists to avoid breaking imports in files that still reference it
export 'tactile_button.dart' show TactileButton;

import 'tactile_button.dart';

/// @deprecated Use [TactileButton] instead
typedef CandyButton = TactileButton;
