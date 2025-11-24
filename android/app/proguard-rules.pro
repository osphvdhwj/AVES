-keep class org.beyka.tiffbitmapfactory.**{ *; }
-keep class org.mp4parser.**{ *; }

# referenced from: com.google.crypto.tink
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# ML Kit Text Recognition - CRITICAL FOR RELEASE BUILDS
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# TensorFlow Lite (used by ML Kit)
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**

# Preserve ML Kit model files
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
