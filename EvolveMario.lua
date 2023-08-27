if gameinfo.getromname() == "Super Mario World (USA)" then
  Filename = "DP1.state"
  ButtonNames = {
    "A",
    "B",
    "X",
    "Y",
    "Up",
    "Down",
    "Left",
    "Right",
  }
elseif gameinfo.getromname() == "Super Mario Bros." then
  Filename = "SMB1-1.state"
  ButtonNames = {
    "A",
    "B",
    "Up",
    "Down",
    "Left",
    "Right",
  }
end

BoxRadius = 6
InputSize = (BoxRadius*2+1)*(BoxRadius*2+1)
rightmost = 0
basbireysayi = 1 --luada diziler 1.indisten başlıyor. C deki gibi 0 değil.
generasyoncount=1 -- jenerasyon sayımı.
popBuyukluk = 3 
TimeoutConstant = 20
Inputs = InputSize+1
Outputs = #ButtonNames
i=1
currentFrame = 0
timeout = 20
bas_pop = {} -- baslangicta içi boş olan popülasyon dizisi tanımlanır. global olarak kullanacaktır. bu bireylerin normal dizisi.
bas_pop_buton = {} -- bu da bireylerin butona basma zamanlarını tutan baslangic popülasyonu olacak.

gen_uzunluk = 10 --istenilen gen uzunluğu miktarı ayarlanır.
ortalamafitnessyaz = 0
eniyiolan = {}
eniyiolan_buton ={}
eniyiolan_fitness = 0
mutation_rate = 4 --1 ile 100 arasında verilecek bir değer ile mutasyon fonksiyonlarındaki kaç oranlı olarak mutasyon olacağı değiştirilir. konsol üzerinde de değiştirebilmek için burada setlenmiştir. 


index_btn = 1
main_loopControl = false
playTop_playControl = false

function getPositions()
  if gameinfo.getromname() == "Super Mario World (USA)" then
    marioX = memory.read_s16_le(0x94)
    marioY = memory.read_s16_le(0x96)
    
    local layer1x = memory.read_s16_le(0x1A);
    local layer1y = memory.read_s16_le(0x1C);
    
    screenX = marioX-layer1x
    screenY = marioY-layer1y
  elseif gameinfo.getromname() == "Super Mario Bros." then
    marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
    marioY = memory.readbyte(0x03B8)+16
  
    screenX = memory.readbyte(0x03AD)
    screenY = memory.readbyte(0x03B8)
  end
end

function getTile(dx, dy)
  if gameinfo.getromname() == "Super Mario World (USA)" then
    x = math.floor((marioX+dx+8)/16)
    y = math.floor((marioY+dy)/16)
    
    return memory.readbyte(0x1C800 + math.floor(x/0x10)*0x1B0 + y*0x10 + x%0x10)
  elseif gameinfo.getromname() == "Super Mario Bros." then
    local x = marioX + dx + 8
    local y = marioY + dy - 16
    local page = math.floor(x/256)%2

    local subx = math.floor((x%256)/16)
    local suby = math.floor((y - 32)/16)
    local addr = 0x500 + page*13*16+suby*16+subx
    
    if suby >= 13 or suby < 0 then
      return 0
    end
    
    if memory.readbyte(addr) ~= 0 then
      return 1
    else
      return 0
    end
  end
end

function getSprites()
  if gameinfo.getromname() == "Super Mario World (USA)" then
    local sprites = {}
    for slot=0,11 do
      local status = memory.readbyte(0x14C8+slot)
      if status ~= 0 then
        spritex = memory.readbyte(0xE4+slot) + memory.readbyte(0x14E0+slot)*256
        spritey = memory.readbyte(0xD8+slot) + memory.readbyte(0x14D4+slot)*256
        sprites[#sprites+1] = {["x"]=spritex, ["y"]=spritey}
      end
    end   
    
    return sprites
  elseif gameinfo.getromname() == "Super Mario Bros." then
    local sprites = {}
    for slot=0,4 do
      local enemy = memory.readbyte(0xF+slot)
      if enemy ~= 0 then
        local ex = memory.readbyte(0x6E + slot)*0x100 + memory.readbyte(0x87+slot)
        local ey = memory.readbyte(0xCF + slot)+24
        sprites[#sprites+1] = {["x"]=ex,["y"]=ey}
      end
    end
    
    return sprites
  end
end

function getExtendedSprites()
  if gameinfo.getromname() == "Super Mario World (USA)" then
    local extended = {}
    for slot=0,11 do
      local number = memory.readbyte(0x170B+slot)
      if number ~= 0 then
        spritex = memory.readbyte(0x171F+slot) + memory.readbyte(0x1733+slot)*256
        spritey = memory.readbyte(0x1715+slot) + memory.readbyte(0x1729+slot)*256
        extended[#extended+1] = {["x"]=spritex, ["y"]=spritey}
      end
    end   
    
    return extended
  elseif gameinfo.getromname() == "Super Mario Bros." then
    return {}
  end
end

function getInputs()
  getPositions()
  
  sprites = getSprites()
  extended = getExtendedSprites()
  
  local inputs = {}
  
  for dy=-BoxRadius*16,BoxRadius*16,16 do
    for dx=-BoxRadius*16,BoxRadius*16,16 do
      inputs[#inputs+1] = 0
      
      tile = getTile(dx, dy)
      if tile == 1 and marioY+dy < 0x1B0 then
        inputs[#inputs] = 1
      end
      
      for i = 1,#sprites do
        distx = math.abs(sprites[i]["x"] - (marioX+dx))
        disty = math.abs(sprites[i]["y"] - (marioY+dy))
        if distx <= 8 and disty <= 8 then
          inputs[#inputs] = -1
        end
      end

      for i = 1,#extended do
        distx = math.abs(extended[i]["x"] - (marioX+dx))
        disty = math.abs(extended[i]["y"] - (marioY+dy))
        if distx < 8 and disty < 8 then
          inputs[#inputs] = -1
        end
      end
    end
  end
  
  --mariovx = memory.read_s8(0x7B)
  --mariovy = memory.read_s8(0x7D)
  
  return inputs
end

function sigmoid(x)
  return 2/(1+math.exp(-4.9*x))-1
end

function clearJoypad()
  controller = {}
  for b = 1,#ButtonNames do
    controller["P1 " .. ButtonNames[b]] = false
  end
  joypad.set(controller)
end

function initializeRun()
  savestate.load(Filename);
  rightmost = 0
  timeout = TimeoutConstant
  clearJoypad()
end

function evaluateCurrent()


  inputs = getInputs()
  controller = evaluateNetwork(genome.network, inputs)
  
  if controller["P1 Left"] and controller["P1 Right"] then
    controller["P1 Left"] = false
    controller["P1 Right"] = false
  end
  if controller["P1 Up"] and controller["P1 Down"] then
    controller["P1 Up"] = false
    controller["P1 Down"] = false
  end

  joypad.set(controller)
end

--Bazı hazır tanımlanması gereken sabitler ve fonksiyonları içeriyor.
--neatEvolve algoritmasında kullandığı fonksiyonlardır ve gerekli olduğu için birebir aktarılmıştır.

function populasyonolustur(Bas_Pop_L, Bas_Pop_Btn) --Başlangıç populasyonu oluşturulur
	if basbireysayi < popBuyukluk+1 then
		Bas_Pop_L[basbireysayi] = baslangicgenomolustur()
		Bas_Pop_Btn[basbireysayi] = baslangicButonZamanlariOlustur()
	end
end

function baslangicgenomolustur() --Rastgele Genom Oluşturma
local dizi = {}
for temp = 1,gen_uzunluk do
table.insert(dizi,temp,math.random(1,8)) -- butonlara karşılık gelmesi için indislere 1 ile 8 arası değer atar.
end
return dizi
end

function caprazla(eniyibirey, diger_birey) -- ilk 3 geni single point olarak crossover yapar.--şuan aktif değil. istenirse kullanılabilir.
	
	console.writeline("---------------------")
	console.writeline("caprazlama Fonksiyonuna girildi.")
	
	local eniyibirey_kopya = deepCopy(eniyibirey)
	local diger_birey_kopya = deepCopy(diger_birey)

	local x = 1
	for x = 1,3 do -- 1. ve 2. indislerinin sırasıyla yer değiştirilmesi için.
	eniyibirey_kopya[x] = diger_birey_kopya[x] -- en iyi bireyin 1, 2... indis genleri diğer bireyin indisindeki input değerleriyle değiştirilir.
	--console.writeline("değiştirilen en iyi birey kopya x: " ..eniyibirey_kopya[x])
	end
	--console.writeline("eniyibireykopya yazdir:")
	--console.writeline(eniyibirey_kopya)
	return eniyibirey_kopya -- en son caprazlanma işlemi biten 2.3.4.5. elaman.
end

function caprazla_uniform(eniyibirey, diger_birey) --bu fonksiyon eniyi birey ile diğer bireylerin çaprazlamaları için kullanılabilir, ya da herhangi 2 bireyin çaprazlamaları için kullanılabilir. 

	--uniform da single point crossover dan farklı olarak daha fazla genin değişme ihtimali olabiliyor. 
	-- single point crossover da ise istenilen bölgeler sadece değişiyor bu pek işimize gelmeyebilir çeşitlilk açısından bu önemli.
	
	local eniyibirey_kopya = deepCopy(eniyibirey)
	local diger_birey_kopya = deepCopy(diger_birey)
	local offspring = {}
	
	--Örnek, A={1,2,3,4} B={5,6,7,8} olursa,
	--Uniform Crossover yapıldığında üretilen nesil, offspring,
	--şans 1 ise A dan gen alır, 2 ise B den gen alır.
	--örnek 1122 geldiğinde, offspring = {1,2,7,8}olur.
	
	local counter = 1
	for counter = 1, gen_uzunluk do
	local sans = math.random(1,2) -- 1 yada 2 yi rastgele üretir. yarı yarıya şans için.
	
	if(sans == 1) then
	-- en iyi bireyden gen alsın.
	offspring[counter] = eniyibirey_kopya[counter]
	elseif(sans == 2) then
	--eğer 2 gelirse diğer bireyden gen alsın.
	offspring[counter] = diger_birey_kopya[counter]
	end
	end

	return offspring -- oluşan evlat birey, yani offspring 
end

function fitnesshesapla() --Fitness değerini gidebildiği son noktaya göre hesapladık

	getPositions()
if marioX > rightmost then
    rightmost = marioX
end
	return rightmost
end

function zamanekle() --Eğer birey ilerlemeye devam ediyorsa zaman eklenir, ilerleyişi durduysa sonraki bireye geçilir
getPositions()
if marioX > rightmost then
    timeout = TimeoutConstant
else  
	timeout = timeout - 1 
end
end

function maincalistir() -- Populasyonu çağırdığımız fonksiyon
	rightmost = 0
	if generasyoncount == 1 and basbireysayi<popBuyukluk+1 then 
		populasyonolustur(bas_pop, bas_pop_buton)
	else
	
		if basbireysayi == popBuyukluk+1 then
		i=1
		generasyoncount = generasyoncount + 1 -- bir soranki jenerasyon için
		basbireysayi = 1
		ortalamafitnessyaz = ortalamafitness(bas_pop) --önceki jenerasyonun fitness ortalaması
		console.writeline(generasyoncount-1 .. ".jenerasyonun ortalama fitness'i: " .. ortalamafitnessyaz)
		console.writeline("En iyi birey'in fitness'i:" .. bas_pop[bestgenom(bas_pop)][gen_uzunluk+1])
		
		yeniGenerasyon(bas_pop, bas_pop_buton)
		end
	end
end

function yazdir()  --Ekrana yazdırma fonksiyonu
console.writeline(basbireysayi .. ".birey")
console.writeline(bas_pop[basbireysayi])
console.writeline(bas_pop_buton[basbireysayi])
end

function yeniGenerasyon(gecerli_pop, gecerli_pop_buton) --Yeni generasyon oluşturup mutasyon ve çaprazlamaları gerçekleştirdiğimiz fonksiyon 

local y = 0 --ortalama pop a sayı index li yazması için garanti edilir.
local gecicipop = {}
local gecicipop_buton = {}
local ortalamapop = {}
local gecicifitnesstoplam = 0
local ortalamaFitness = 0


for gecicigenom = 1,popBuyukluk do --fitness toplamı bulunur.
gecicifitnesstoplam = gecerli_pop[gecicigenom][gen_uzunluk+1] + gecicifitnesstoplam
end


ortalamaFitness = gecicifitnesstoplam / popBuyukluk -- popülasyonun ortalama fitness bulundu.


for gecicigenom = 1,popBuyukluk do --ortalama üstü fitness olanları gecici bir diziye aktardık. --opsiyonel 
	
	if gecerli_pop[gecicigenom][gen_uzunluk+1] >= ortalamaFitness then --popülasyondaki ortalama üstü fitnessa sahip bireyler bulunur.
		y = y+1 --ortalama üstü bireyleri sırasıyla 1 2 3 diye ortalamapop dizisine yazmak için bu lazım.
		table.insert(ortalamapop,y,gecerli_pop[gecicigenom]) -- bulunan bireyler ortalamapop dizisine aktarılır.
	end
end

----------------------------------------------------------------------------------------------------------------------------

--popülasyon dizisi tamamen gecicipop a aktarılır.
gecicipop = deepCopy(gecerli_pop)
-- en iyi olan elemanın indisi bestgenom fonk ile bulunur.
local eniyibirey = deepCopy(gecerli_pop[bestgenom(gecerli_pop)]) -- en iyi bireyin indisini bulur ve indisinden kendisi bulur onu gecici bir temp_bireye kopyalar.
gecicipop[bestgenom(gecerli_pop)] = deepCopy(gecicipop[1])
gecicipop[1] = deepCopy(eniyibirey) -- eniyi fitnessli birey temp_bireyden 1. indise aktarılır. 
--böylece elit 1 de, kalanlar 2345... şeklinde olur.
-----------------

--butonlara da aynısı yaptırılır.
gecicipop_buton = deepCopy(gecerli_pop_buton)
local eniyibirey_buton = deepCopy(gecicipop_buton[bestgenom(gecerli_pop)]) -- en iyi bireyin indisini bulur ve indisinden kendisi bulur onu gecici bir temp_bireye kopyalar.
gecicipop_buton[bestgenom(gecerli_pop)] = deepCopy(gecicipop_buton[1])
gecicipop_buton[1] = deepCopy(eniyibirey_buton) -- eniyi fitnessli birey temp_bireyden 1. indise aktarılır. 
--böylece elit 1 de, kalanlar 2345... şeklinde olur.

-----------------------------------------------------------------------------------------------------------------

if(generasyoncount==2) then --ilk jenerasyon bittiğinde,--bu adım globalde eniyifitnessli bireyi tutmak içindir. opsiyonel.
--başlangıçta en iyi olan bireyi aynen alacağız. sonrasında karşılaştırarak alacağız.
eniyiolan_fitness = deepCopy(eniyibirey[gen_uzunluk+1])
eniyiolan = deepCopy(eniyibirey)
eniyiolan_buton = deepCopy(eniyibirey_buton)
else
--sonraki jenerasyonlarda ise fitnesslari karşılaştırır,
if(eniyiolan_fitness < eniyibirey[gen_uzunluk+1]) then
eniyiolan_fitness = deepCopy(eniyibirey[gen_uzunluk+1])
eniyiolan = deepCopy(eniyibirey)
eniyiolan_buton = deepCopy(eniyibirey_buton)
end
end

local copy_gecerli_pop = {}
local copy_gecerli_pop_buton = {}
copy_gecerli_pop = deepCopy(gecicipop) --en iyinin başta olduğu dizi kopyalanır. böylece caprazlamada 234 seklinde döngü dönebilir.
copy_gecerli_pop_buton = deepCopy(gecicipop_buton)
-- burada yapılacak olan 1.ye eliti atmak, kalan 234.. doldurmak için caprazla roulet fonksiyonuna gitmek. caprazla kısmı tamamen o fonkta olmalı.

-- 2 3 .. defa offspring olusturmak üzere çalışacak.  etkiler direkt copy ler üzerinde olucak. yani bu diziler değişecek.
caprazla_roulette(copy_gecerli_pop,copy_gecerli_pop_buton) --kopyaları içeri girecek aslı bozulmasın diye.

bas_pop = copy_gecerli_pop
bas_pop_buton = copy_gecerli_pop_buton
end

function bestgenom(gecerli_pop) --eniyigenoma sahip birey bulunur.
local i = 1 --döngüye girecek değişken 1 den başlayacak çünkü diziler indis 1 den başlıyor.
maxgenom = 0
maxgenomkonum = 0 --popülasyondaki hangi birey en yüksek fitness a sahip onu bulmak için dizideki konumu aranıyor.
for i = 1,#gecerli_pop do --dizi uzunluğu kadar popülasyona bakılır.
if maxgenom < gecerli_pop[i][gen_uzunluk+1] then --yani bireylerin gen uzunlugunun 6 olduğu durumlarda 7.indis fitness i tutar. o yüzden 7.ye bakılır.
maxgenom = gecerli_pop[i][gen_uzunluk+1]
maxgenomkonum = i
end
end
return maxgenomkonum
end

function ortalamafitness(gecerli_pop) --Fitness ortalamasını hesapla
local gecicifitnesstoplam = 0
local gecicigenom = 0
	for gecicigenom = 1,popBuyukluk do --Ortalama aldırdık
	gecicifitnesstoplam = gecerli_pop[gecicigenom][gen_uzunluk+1] + gecicifitnesstoplam
	end
	gecicifitnesstoplam = gecicifitnesstoplam / popBuyukluk
	
	return gecicifitnesstoplam
end

function deepCopy(orig)
	local copy 
	if type(orig) == 'table' then
		
		copy = {}
		for orig_key,
		orig_value in next, orig, nil do
		
		copy[deepCopy(orig_key)] = deepCopy(orig_value)
		end
		setmetatable(copy, deepCopy(getmetatable(orig)))
	else 
		copy = orig
	end
	return copy
end

function pressTheButtonForFrames(framesToPress, buttonToPress) --butona kaç frame boyunca basacak.
	for frame = 1, framesToPress do --Butonlara bastırılan kısım
		-- set the button state to pressed
	controller[buttonToPress] = true
	joypad.set(controller)
	guiYazdir()
	emu.frameadvance();
	end
	
	releaseTheButton(buttonToPress)
end

function releaseTheButton(buttonPressed)
		--örnek "P1 A" geldi.
		controller[buttonPressed] = false
		joypad.set(controller)
		guiYazdir()
		emu.frameadvance();	
end

function baslangicButonZamanlariOlustur() --Rastgele Genom Oluşturma
local dizi = {}

for temp = 1, gen_uzunluk do -- her bir tuş geni için tuş basma zamanı sayısı 
-- 1 2 4 8 12 kare arası olacak şekilde rastgele butona basma zamanları oluşturulacak.
table.insert(dizi,temp,randomBtnZamanlariOlustur()) --tuşa basma zamanı sayıları diziye aktarılır.
end

return dizi --bu dizi tuşa basma zamanı dizisi olmak üzere geri dönecektir.
end

function randomBtnZamanlariOlustur() --random kademeli buton zamanlaması olusturma işleminin matematiksel mantığı burada yapılır.
local rastgeleSayi = 0
local rastgeleSayiSon = 0

rastgeleSayi = math.random(1,5)

	if(rastgeleSayi == 1) then
	rastgeleSayiSon = 1
	
	elseif(rastgeleSayi == 2) then
	rastgeleSayiSon = 2
	
	elseif(rastgeleSayi == 3) then
	rastgeleSayiSon = 4
	
	elseif(rastgeleSayi == 4) then
	rastgeleSayiSon = 8
	
	elseif(rastgeleSayi == 5) then
	rastgeleSayiSon = 12
end

return rastgeleSayiSon
end

function mutasyon_v2(tempgenom) -- bu mutasyon türü, her bir gen için sabit oranda bir şans ile mutasyon uygular. Örnek her bir gen için %40 oranında mutasyon şansı vardır. 
--console.writeline("Mutasyon öncesi:")
--console.writeline(tempgenom)
local sans = 0
local current_value = 0
local new_value = 0
for x = 1, gen_uzunluk do 
sans = math.random(1,100)
--console.writeline("Şans: " ..sans)
if (sans <= mutation_rate) then -- global mutasyon yüzdesi. 
currentValue = tempgenom[x] --mevcut değerini al.
new_value = math.random(1,8)
while(currentValue == new_value) do
new_value = math.random(1,8) --eşit olmayana kadar bir değer olustur.
end
tempgenom[x] = new_value
end
end
--console.writeline("Mutasyon sonrası:")
--console.writeline(tempgenom)
end

function mutasyonButonZamanlari_v2(tempgenom) -- bu mutasyon türü, her bir gen için sabit oranda bir şans ile mutasyon uygular. Örnek her bir gen için %40 oranında mutasyon şansı vardır. 
--console.writeline("Mutasyon öncesi:")
--console.writeline(tempgenom)
local sans = 0
local current_value = 0
local new_value = 0
for x = 1, gen_uzunluk do 
sans = math.random(1,100)
--console.writeline("Şans: " ..sans)
if (sans <= mutation_rate) then --global mutasyon oranı
--console.writeline("şans değeri girdi, btnzaman")
currentValue = tempgenom[x] --mevcut değerini al.
new_value = randomBtnZamanlariOlustur()
while(currentValue == new_value) do
new_value = randomBtnZamanlariOlustur() --eşit olmayana kadar bir değer olustur.
end
tempgenom[x] = new_value
end
end
--console.writeline("Mutasyon sonrası:")
--console.writeline(tempgenom)
end

function guiYazdir()
	gui.drawText(0, 36, "Fitness: " .. fitnesshesapla() , 0xFF000000, 11) --Ekrana fitness'ı anlık olarak görüntüledik
	gui.drawText(0, 60, "Birey: " .. basbireysayi , 0xFF000000, 11) --Ekrana birey'ı anlık olarak görüntüledik
	gui.drawText(100, 36, "Jenerasyon: " .. generasyoncount , 0xFF000000, 11)	--Ekrana Populasyonu'ı anlık olarak görüntüledik
	gui.drawText(100, 60, "Pop Ortalama: " .. ortalamafitnessyaz , 0xFF000000, 11)	--Ekrana Populasyonu'ı anlık olarak görüntüledik--ortalamafitnessyaz

end

function roulette_wheel_selection(arr_fitness) -- fitnessların olduğu dizi gönderilir.
--0 dan toplam fitness a kadar.
local fitness_toplam = 0
local sum_array = 0
--toplam fitness i bulmak için tüm fitnesslari topla
-- kümülatif toplam diziyi de oluşturur.
for x=1, #arr_fitness do
fitness_toplam = fitness_toplam + arr_fitness[x]
end

--console.writeline("Fitness Toplam: " .. fitness_toplam)

local random_number = math.random(1,fitness_toplam)
--console.writeline("Random Sayi: " ..random_number)

for x=1, #arr_fitness do --random sayı hangi aralığa gelirse.
sum_array = sum_array + arr_fitness[x]
if(sum_array >= random_number) then
return x -- kaçıncı indisteki eleman çekiliyorsa
end
end
end

function caprazla_roulette(current_pop,current_pop_buton) -- kaç tane offspring üretilecekse kalan popülasyondaki caprazlamaların seçimini yapacak
--içeri tüm populasyonu elit başta olacak şekilde olduğu gibi girdireceğiz, ardından rulet ile seçilen 2 bireyi çaprazlayacağız ve uniformdan çıkanları da diziye ekeleyecğiz..

local degismez_current_pop = deepCopy(current_pop) --bunlar değişmeyecek olanlar
local degismez_current_pop_buton = deepCopy(current_pop_buton) --bunlar değişmeyecek olanlar.

local secilen_birey_1 = {} --rulette 1.
local secilen_birey_2 = {} --rulette 2.sırada seçilen.
local secilen_birey_1_buton = {}
local secilen_birey_2_buton = {}

local arr_fitness = {} -- sadece fitnessların tutulduğu dizi.

for x=1, popBuyukluk do
table.insert(arr_fitness,x,deepCopy(degismez_current_pop[x][gen_uzunluk+1])) --fitnesslari al.
end



for x=2, popBuyukluk do --1. indis hariç kalan indisleri için .. üretim yapacak. çünkü 1 tane elitimiz var.

local copy_current_pop = deepCopy(degismez_current_pop) --içeri giren birey dizisinin değişecek kopyası çünkü eksiltme işlemi yapılıyor.
local copy_current_pop_buton = deepCopy(degismez_current_pop_buton) --içeri giren birey dizisinin değişecek kopyası çünkü eksiltme işlemi yapılıyor.

local offspring = {}
local offspring_buton = {}
local copy_arr_fitness = deepCopy(arr_fitness)


local indis_birey_1 = roulette_wheel_selection(copy_arr_fitness)
--indis 1i listeden çıkart.
table.remove(copy_arr_fitness,indis_birey_1)
table.remove(copy_current_pop,indis_birey_1)
table.remove(copy_current_pop_buton,indis_birey_1)
local indis_birey_2 = roulette_wheel_selection(copy_arr_fitness)
--seçimler yapıldı.

secilen_birey_1 = deepCopy(degismez_current_pop[indis_birey_1])
secilen_birey_2 = deepCopy(copy_current_pop[indis_birey_2])
secilen_birey_1_buton = deepCopy(degismez_current_pop_buton[indis_birey_1])
secilen_birey_2_buton = deepCopy(copy_current_pop_buton[indis_birey_2])
--seçilen bireyler çekildi.

--2 birey gerek buton gerekse de normal dizilerinde caprazlandıklarında oluşan offspringler tutulur.
offspring = deepCopy(caprazla_uniform(secilen_birey_1,secilen_birey_2))
mutasyon_v2(offspring) --eğer mutasyon yapaacaksak.
offspring_buton = deepCopy(caprazla_uniform(secilen_birey_1_buton,secilen_birey_2_buton))
mutasyonButonZamanlari_v2(offspring_buton)

current_pop[x] = deepCopy(offspring)
current_pop_buton[x] = deepCopy(offspring_buton)

end

end

function saveTop() -- en iyi bireyi dosyaya kaydeder.
--yeni bir dosya oluştur.
local file = io.open("savedTopFitness.txt", "w")

if file then
--değişkenleri dosyaya yaz-kaydet
if(eniyiolan_fitness == 0) then
console.writeline("Henüz Max Fitness 0.")

else
file:write("Max Fitness: " .. eniyiolan_fitness .. "\n")
file:write("Genom:" .. "\n")
for x=1, gen_uzunluk+1 do
file:write(eniyiolan[x] .."\n")
end 
file:write("Buton Dizisi:" .."\n")
for x=1, gen_uzunluk do
file:write(eniyiolan_buton[x] .."\n")
end
console.writeline("Dosya olusturuldu ve kaydedildi.")
end

--dosyayı kapat 
file:close()
else
console.writeline("Dosya olusturulamadı.")
end
end

function savePool() -- current popülasyonu bir dosyaya kaydeder. 
--yeni bir dosya oluştur.
local file = io.open("savedPool.txt", "w")

if file then
--değişkenleri dosyaya yaz-kaydet

file:write(generasyoncount .. ".Jenerasyon " .. "Popülasyon Dizileri" .. "\n")
for x=1, popBuyukluk do
file:write(x..".birey:".."\n")
for y=1, gen_uzunluk do
file:write(bas_pop[x][y])
file:write("\n")
end
end 
file:write("Buton Dizileri" .."\n")
for x=1, popBuyukluk do
file:write(x..".birey_buton:".."\n")
for y=1, gen_uzunluk do
file:write(bas_pop_buton[x][y])
file:write("\n")
end
end 
console.writeline("Dosya olusturuldu ve kaydedildi.")

--dosyayı kapat 
file:close()
else
console.writeline("Dosya olusturulamadı.")
end
end

function loadPool()
-- kontrolü setle böylece buton basma eyleminden çıksın
main_loopControl = true --ana döngüden çıkılır.
console.writeline("yükleme yapılıyor.")

--dosyayı okuma modunda aç
local file = io.open("savedPool.txt", "r")
local lineCount = 0
local counter_index = 0

if file then
for line in file:lines() do
lineCount = lineCount+1 --satır sayısını hesaplayacak.

if line and line:find(".birey:") then --bireyi buldu ve onun dizisini aktaracak,
counter_index = counter_index + 1
for x=1, gen_uzunluk do
--console.writeline("Genler yazılacak")
local next_line = file:read("*l")
--console.writeline(next_line)
bas_pop[counter_index][x] = tonumber(next_line)
--console.writeline("counter:"..counter_index)
--console.writeline("bas_pop = " ..bas_pop[counter_index][x])
end
elseif line and line:find(".birey_buton:") then
--console.writeline("buton dizisi bulundu")
counter_index = counter_index + 1
for x=1, gen_uzunluk do
--console.writeline("Buton zamanlari yazilacak")
local next_line = file:read("*l")
--console.writeline(next_line)
bas_pop_buton[counter_index][x] = tonumber(next_line)
--console.writeline("counter:"..counter_index)
--console.writeline("bas_pop = " ..bas_pop_buton[counter_index][x])
end
else
counter_index = 0
end
end
--dosyayı kapat.
file:close()

clearJoypad()
basbireysayi = 1
rightmost= 0
i=1

savestate.load(Filename);
timeout= TimeoutConstant

main_loopControl = false

else
--dosya bulunamadı.
console.writeline("Dosya bulunamadi.")
end
end

function playTop() --en iyi bireyi oynatma fonksiyonu.
--bu fonksiyon bazen en iyi bireyi oynatırken farklı sonuçlar verebiliyor
--ancak doğru şekilde oynattığı da oluyor henüz hata çözülmedi.
if(eniyiolan_fitness == 0) then
console.writeline("En iyi fitness henüz 0.")
else
main_loopControl = true
clearJoypad()
console.writeline("En iyi fitness birey oynatılıyor.")

--oynatılmadan önce hangi birey mevcut jenerasyon bilgisi ve kaçıncı bireyini oynatıldığına dair bilgi çekilir.
--böylece en iyi fitness li TOP birey oynatıldıktan sonra algoritma kaldığı yerden devam edebilir.
--jenerasyon sayısı, kaçıncı birey sayısında kaldıysa çekilir,
--burada  en iyi bireyi oynatma başlatılır,

copy_basbireysayi= basbireysayi
index_btn = 1
rightmost= 0
savestate.load(Filename);
timeout= TimeoutConstant
playTop_playControl = true
end
end


clearJoypad()
populasyonolustur(bas_pop, bas_pop_buton)
savestate.load(Filename);

while true do 
while main_loopControl==false do --Ana fonksiyon

	
	pressTheButtonForFrames(bas_pop_buton[basbireysayi][i], "P1 " .. ButtonNames[bas_pop[basbireysayi][i]])
	bas_pop[basbireysayi][gen_uzunluk+1] = rightmost --Her bireyin gen_uzunluk+1. gen'i fitness'a ayrılır
	
	zamanekle()
	i=i+1
	
	if i == gen_uzunluk then
	i = 1
	end
	
	if timeout <= 0 then --Reset
	
	i=1
	basbireysayi = basbireysayi+1
	maincalistir()
	savestate.load(Filename);
	timeout = TimeoutConstant
	end
	
	
end


while main_loopControl and playTop_playControl do --en iyi bireyi oynatma kısmı
	
	
	
	pressTheButtonForFrames(eniyiolan_buton[index_btn], "P1 " .. ButtonNames[eniyiolan[index_btn]])

	zamanekle()
	index_btn=index_btn+1
	
	
	if index_btn == gen_uzunluk then
	index_btn = 1
	end
	
	
	if timeout <= 0 then --Reset
	console.writeline("En iyi oynatma işlemi tamamlandi.")
	console.writeline("eniyi rightmost =" ..rightmost)
	playTop_playControl = false
	savestate.load(Filename);
	timeout =TimeoutConstant
	rightmost = 0
	i = 1
	basbireysayi = copy_basbireysayi
	main_loopControl = false
	end
end

end






