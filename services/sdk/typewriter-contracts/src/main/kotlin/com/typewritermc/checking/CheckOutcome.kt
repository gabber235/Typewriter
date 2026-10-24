package com.typewritermc.checking

import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.ValueLocation

val CheckOutcome.NeedsInputWrapper.locations: List<ValueLocation> get() = value

val CheckOutcome.FailedWrapper.diagnostics: List<Diagnostic> get() = value

val CheckOutcome.IncompleteWrapper.reason: String get() = value
