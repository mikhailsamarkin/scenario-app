# Firebase ComponentDiscovery создаёт реализации ComponentRegistrar через
# рефлексию (Class.forName(...).getDeclaredConstructor().newInstance()).
# В release R8 full mode удаляет их конструктор без аргументов, из-за чего
# Firebase.initializeApp падает с "FirebaseCrashlytics component is not present".
# Потребительские правила firebase-components сохраняют только класс без членов,
# поэтому конструктор нужно удерживать явно.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
