# Model prawdopodobieństwa wearów

Generator dobiera konkretne elementy sekwencyjnie. Bazowa szansa dodania
pierwszego elementu wynosi 78%, drugiego 48%, trzeciego 12%, czwartego 2%,
a piątego 0,2%. Tryb losowania i złożoność modyfikują tę krzywą, ale nie
omijają kontroli czytelności.

Każdy wariant ma profil zasłonięcia sześciu stref: twarzy, oczu, głowy,
tułowia, rąk i zewnętrznego konturu. Strefy mają wagi odpowiednio 2,0; 2,5;
1,3; 1,0; 0,8 i 1,5. Nakładanie dwóch elementów w tej samej strefie dodaje
osobną karę, więc helmet i maska kosztują znacznie więcej niż dwa drobne
elementy.

Po każdym kandydacie generator oblicza łączny wynik zasłonięcia. Szansa
akceptacji wynosi 100% do 20 punktów, 75% do 35, 35% do 50, 10% do 65,
2% do 80 i 0,2% do 90. Powyżej 90 zwykłe losowanie odrzuca zestaw.

Konflikty chronią oczy, twarz i sylwetkę. Zamknięty helmet wyklucza maskę
i okulary, pełna maska wyklucza okulary, a ciężki armor nie może łączyć się
jednocześnie z cape i shoulder propem. W zwykłym losowaniu wybierany jest
maksymalnie jeden element z jednej rodziny wizualnej.

Pełny zestaw jest osobnym deterministycznym zdarzeniem `1 / 30_000`. Nie
korzysta ze zwykłej krzywej akceptacji, ale końcowy post-processing nadal
usuwa geometrycznie sprzeczne warstwy. Ręczne override’y i presety archetypów
pozostają nadrzędne wobec probabilistyki.

Companion jest rzadką klasą: 2% w `natural`, 4% w `diverse`, 3% w
`stylized`, 6% w `fantasy`, 5% w `scifi`, 10% w `rareHeavy`, 12% w
`chaotic` i 0,5% w `minimal`. Jawny wybór companiona zawsze jest respektowany.
