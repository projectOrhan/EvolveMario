# EvolveMario
Genetik Algoritma methodları kullanılarak Lua Dilinde yazılmış bir scripttir. Super Mario oyununda karakterin kendi kendine bölümleri geçmesini amaçlar. 

NeatEvolve algoritması baz alınarak tasarlanmıştır. NeatEvolve, algoritmasından farkı Yapay Sinir Ağı kullanmıyor olmasıdır. Kısacası, bu Algoritma sadece Genetik Algoritma methodları kullanarak tasarlanmıştır. Bu çalışmadaki amaç Yapay Sinir Ağları olmadan tasarlanan bir Evrim Algoritmasının istenen sonuçlara ulaşmadaki öğrenme hızı, öğrenme limitleri gibi detayları gözlemlemek ve deneyimlemektir. Ek olarak, Genetik Algoritmalardaki Yerel Optimumda sıkışma-takılma, üretilecek yeni nesillerde yeterli gen çeşitliliğini sağlamak, iyi genlerin korunumunu sağlamak gibi sık sık gözlemlenen optimizasyon problemlerinin çözümleri de deneyimlenmiş oldu.

#Algoritma Detayları

İlk kez çalıştırıldığında, 1.jenerasyon bireyleri oluşturulur. Bu adımda, tamamen rastgele genlere sahip bireyler ilk jenerasyonu oluşturacaktır.
Ardından bu ilk jenerasyonun bireyleri oyunda gösterecekleri ilerlemeye bağlı olarak bir Fitness(Başarım) değeri alacaklar. Bu değer onların oyunda ilerleme anlamında ne kadar başarılı olduklarını gösterecek diyebiliriz.

Bu algoritma jenerasyonlar boyunca en iyi genlere sahip bireyi her zaman korur, ta ki daha iyi bir başarıma sahip bir birey elde edilene kadar. Örneğin, 1.Jenerasyondaki 12.Birey en iyi Fitness(Başarım) değerine sahip ise bu birey gelecek jenerasyon olan 2.Jenerasyonun üretim aşamasında, hiç değişmeden, 2.jenerasyonun 1.bireyi olacak şekilde aktarılır. Ardından boşta kalan bireylerin üretilmesi işlemi yapılır. Bu üretim yapılırken geçerli jenerasyon üzerinde bireylerin Fitness(Başarım) değerleriyle orantılı olacak şekilde bir Rulet Seçim uygulanır. Ardından Rulet Seçim sonucu seçilen iki birey Uniform Çaprazlama işlemi ile bir Evlat Birey üretirler. Bu evlat bireye ardından Mutasyon uygulanır. Ardından bu evlat birey 2.birey olarak gelecek jenerasyona aktarılmış olur. Kalan 3.4.5... gibi bireyler de yine aynı yöntemle üretilir ve jenerasyon tamamen doldurulmuş olur.

Üretim aşamasından sonra,
Bu bireyler yine başlangıç jenerasyonunda olduğu gibi oyundaki gösterecekleri ilerlemeye bağlı olarak bir Fitness(Başarım) değeri alacaklardır. Ve aynı üretim aşamalarından geçerek yeni nesilleri oluşturacaklardır. Algoritma bu şekilde sürekli daha yüksek Fitness(Başarım) değerlerine sahip bireyleri arayacak şekilde devam etmiş olacaktır.

#Kullanılan Genetik Algoritmaya Dair Detaylar
--elitism uniform caprazlama ve mutasyon.
Bu algoritmada Elitist yaklaşım kullanılmıştır. Buradaki amaç en iyi başarım gösteren bireyi nesiller boyunca ondan daha iyi başarım gösteren birey elde edilene kadar koruyarak, yeni nesillerde en iyi bireyin genlerinin  olabildiğince korunmasını sağlamak amaçlanmıştır. Bunun sebebi ise mevcut başarım seviyesi olabildiğince korunarak ilerlemektir. Bu yaklaşımın avantaj ve dezavantajları olduğu için bu algoritmada bu hususlar gözetilmiştir ve bu yöntem seçilmiştir.

Bu algoritmada Uniform Çaprazlama kullanılmıştır. Bu çaprazlama yönteminin seçilmesinin sebebi ise single point ya da multipoint çaprazlama yöntemlerinden farklı olarak daha çok gende değişimi sağlayabilmesidir. Örneğin single point'te sabit bir noktadaki genler karşılıklı olarak değiştirilirken, bu çaprazlama yönteminde evlat bireyin tüm genleri ebeveyn bireylerden rastgele bir şekilde aktarılmaktadır. Diğer bir deyişle, ebeveyn bireylerden gelecek genlerin tamamen %50-%50 şansla gerçekleşmesi göz önüne alındığında, evlat bireye aktarılacak genin ebeveyn birey1 ya da ebeveyn birey2 den gelmesi daha iyi bir çeşitlilik ve rastgelelik(yani bir sonraki adımlarda daha az, ya da daha çok gen değişebilir) sağlamaktadır.







