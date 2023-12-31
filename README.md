# EvolveMario
Lua Dilinde Genetik Algoritma methodları kullanılarak yazılmış bir scripttir. Super Mario oyununda karakterin kendi kendine bölümleri geçmesini amaçlar. 

## Algoritma Hakkında

**NeatEvolve** algoritmasını örnek alarak tasarlanmıştır.  **NeatEvolve**, algoritmasından farkı **Yapay Sinir Ağı** kullanmıyor olmasıdır. Kısacası, bu Algoritma sadece **Genetik Algoritma** methodları kullanarak tasarlanmıştır. Bu çalışmadaki amaç **Yapay Sinir Ağları olmadan** tasarlanan bir **Evrim Algoritmasının** istenen sonuçlara ulaşmadaki öğrenme hızı, öğrenme limitleri gibi detayları gözlemlemek ve deneyimlemektir. Ek olarak, **Genetik Algoritmalardaki Yerel Optimumda sıkışma-takılma**, üretilecek yeni nesillerde yeterli **gen çeşitliliğini** sağlamak, **iyi genlerin korunumunu** sağlamak gibi sık sık gözlemlenen **optimizasyon problemlerinin** çözümleri de deneyimlenmiş oldu.

***NOT: Algoritmanın çalışabilmesi için gereken ve oyundaki RAM değerleri üzerinden yapılan hesaplamaların olduğu fonksiyonlar, örneğin karakterin oyundaki konumu gibi, birebir **NeatEvolve** algoritmasından aktarılmıştır. Dolayısıyla, bu EvolveMario algoritmasının ana işleyişi benim tarafımdan tasarlanmış ve kodlanmıştır. Ancak, algoritmanın çalışabilmesi için gereken yardımcı fonksiyonlar NeatEvolve algoritmasından birebir aktarılmıştır. O yüzden bu çalışmamda NeatEvolve algoritmasını kaynak aldım.***

## Dosyalarla İlgili Detaylar
**DP1.State** dosyası kayıt dosyasıdır. **BizHawk Emulatöründe** **Super Mario** oyununun istenilen bir bölümünden alınan kayıt dosyasıdır. Bu algoritmada, her bir birey için **DP1.State** dosyası yeniden yüklenerek her bir birey aynı kayıt noktasından başlar. Böylece her birey aynı bölüm üzerinde eşit durumlarda test edilmiş olur.

**EvolveMario.lua** dosyası Lua script dosyasıdır. Yazılan bu script BizHawk Emülatöründeki **Lua Console** üzerinden aktive edilerek algoritma çalıştırılabilir.

**savedPool.txt** dosyası bir jenerasyonun tüm bireylerini içeren kayıt dosyasıdır. Gerektiğinde **Lua Console** üzerinden yazılacak **savePool()** komutu ile çalışma anındaki mevcut jenerasyonun tüm bireylerini **savedPool.txt** text dosyasına kaydeder. Böylece bir sonraki çalışmada **loadPool()** komutu ile kaydedilmiş olan jenerasyon algoritmaya yüklenmiş olur. Böylece kaydedilmiş jenerasyondan-ilerlemeden devam edilmiş olacaktır.

**savedTopFitness.txt** gerektiğinde **Lua Console** üzerinden yazılacak **saveTop()** komutu ile çalışma anındaki jenerasyonlar boyunca tüm bireylerin arasında **en yüksek fitness değerine sahip** olan bireyi dosyaya kaydeder. Böylece en yüksek fitness değerine sahip bireyin gen dizilimine dair detaylar dosyaya kaydedilmiş olacaktır. İstenildiğinde **playTop** komutu ile jenerasyonlar boyunca en yüksek fitness değerine sahip bireyi tekrar oynatacaktır.

## Nasıl Çalışır?
Öncelikle **Super Mario** oyunu **BizHawk Emülatöründe** açılır. 
Daha sonra, **Lua Console** üzerinden **EvolveMario.lua** script dosyası aktive edilir. 
Ardından, algoritma çalışmaya başlar.

## Algoritma Detayları

İlk kez çalıştırıldığında, 1.jenerasyon bireyleri oluşturulur. Bu adımda, tamamen rastgele genlere sahip bireyler ilk-başlangıç jenerasyonunu oluşturacaktır.
Ardından bu ilk jenerasyonun bireyleri oyunda gösterecekleri ilerlemeye bağlı olarak bir Fitness(Başarım) değeri alacaklar. Bu değer onların oyunda ilerleme anlamında ne kadar başarılı olduklarını gösterecek diyebiliriz.

Bu algoritma jenerasyonlar boyunca en iyi genlere sahip bireyi korur, ta ki daha yüksek bir başarıma sahip yeni bir birey elde edilene kadar. Örneğin, 1.Jenerasyondaki 12.Birey en iyi Fitness(Başarım) değerine sahip ise bu birey gelecek jenerasyon olan 2.Jenerasyonun üretim aşamasında, hiç değişmeden, 2.jenerasyonun 1.bireyi olacak şekilde aktarılır. Ardından boşta kalan bireylerin üretilmesi işlemi yapılır. Bu üretim yapılırken geçerli jenerasyon üzerinde bireylerin Fitness(Başarım) değerleriyle orantılı olacak şekilde bir Rulet Seçim uygulanır. Ardından Rulet Seçim sonucu seçilen iki birey Uniform Çaprazlama işlemi ile bir Evlat Birey üretirler. Bu evlat bireye ardından Mutasyon uygulanır. Ardından bu evlat birey 2.birey olarak gelecek jenerasyona aktarılmış olur. Kalan 3.4.5... gibi bireyler de yine aynı yöntemle üretilir ve bu yeni jenerasyon tamamen üretilmiş-doldurulmuş olur.

**Üretim aşamasından sonra,**

Bu bireyler yine başlangıç jenerasyonunda olduğu gibi oyundaki gösterecekleri ilerlemeye bağlı olarak bir Fitness(Başarım) değeri alacaklardır. Ve aynı üretim aşamalarından geçerek yeni nesilleri oluşturacaklardır. Algoritma bu şekilde sürekli daha yüksek Fitness(Başarım) değerlerine sahip bireyleri arama amacıyla devam etmiş olacaktır.

## Kullanılan Genetik Algoritmaya Dair Detaylar
Bu algoritmada **Elitist** yaklaşım kullanılmıştır. Bu yaklaşımla en yüksek Fitness(başarım) gösteren bireyi nesiller boyunca ondan daha yüksek başarım gösteren birey elde edilene kadar koruyarak, yeni nesillerde bu en iyi bireyin genlerinin  olabildiğince korunmasını sağlamak amaçlanmıştır. Bunun sebebi ise mevcut başarım seviyesi olabildiğince korunarak ilerlemektir. Yani iyi genlere sahip bireyin genlerinin yeni nesillere daha fazla ihtimalle aktarılmasını sağlamak. Bu yaklaşımın avantaj ve dezavantajları olduğu için bu algoritmada bu hususlar gözetilmiştir ve bu yöntem tercih edilmiştir.

**Çaprazlama:** Yeni nesillerin üretimi aşamasında **Uniform Çaprazlama** yöntemi kullanılmıştır. Bu çaprazlama yönteminin seçilmesinin sebebi ise **single point** ya da **multipoint çaprazlama** yöntemlerinden farklı olarak daha çok gende rastgele bir değişim sağlayabilmesidir. Örneğin, single point çaprazlamada sabit bir noktadaki genler karşılıklı olarak değiştirilirken, bu çaprazlama yönteminde ise evlat bireyin tüm genleri ebeveyn bireylerden rastgele bir şekilde aktarılmaktadır. Diğer bir deyişle, ebeveyn bireylerden gelecek genlerin tamamen %50-%50 şansla gerçekleşmesi göz önüne alındığında, evlat bireye aktarılacak genin ebeveyn birey1 ya da ebeveyn birey2 den gelebilecek olması daha iyi bir çeşitlilik ve rastgelelik(yani bir sonraki adımlarda daha az, ya da daha çok gen ebeveyn birey1den ya da ebeveyn birey2 den aktarılabilir.) sağlamaktadır. Bu Çaprazlama yöntemi bu hususlar dikkate alınarak tercih edilmiştir.

**Mutasyon:** Algoritmada kullanılan Mutasyon tekniğinde ise her bir genin Mutasyon geçirmesi için eşit şansı vardır. Bu durum, her bir gene eşit oranda değişebilme imkanı tanır. Örneğin, mutasyona uğrayacak maksimum gen sayısı sınırlandığında (örnek maksimum 2 gen mutasyona uğrayabilir limiti ayarlandığında) genlerde çeşitlilik daha az oluyor ve algoritma yerel optimum noktasına daha sık takılabiliyor. Dolayısıyla, her bir gene sabit bir mutasyon şansı tanımak gen havuzunun çeşitliliği sağlamak noktasında etkili bir yaklaşım oluyor. Bu Mutasyon yöntemi bu hususlar dikkate alınarak tercih edilmiştir.












