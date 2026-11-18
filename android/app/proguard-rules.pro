-keep class ai.onnxruntime.** { *; }
# The jni package (shared_preferences_android, path_provider_android) looks
# these Kotlin classes up by name from Dart. R8 renamed them in release, so
# getAll's Continuation parameter and CoroutineSingletons were not found.
-keep interface kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
