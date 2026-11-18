# Regenerates the mod artwork (Pillow). Run from tools/: python3 make_images.py
# Outputs random_city.png (1024x768), poster.png (512), preview.png (256), icon.png (64);
# copy them to 42/media/ui/RandomCitySpawn/, 42/, repo root and 42/ respectively.
import random, math
from PIL import Image, ImageDraw, ImageFilter, ImageFont
random.seed(7)
W,H=2048,1536
img=Image.new("RGB",(W,H),(222,208,170))
d=ImageDraw.Draw(img)
# paper noise blotches
for _ in range(400):
    x,y=random.randint(0,W),random.randint(0,H); r=random.randint(20,120)
    c=random.randint(-12,8); col=(222+c,208+c,170+c)
    d.ellipse([x-r,y-r,x+r,y+r],fill=col)
img=img.filter(ImageFilter.GaussianBlur(30)); d=ImageDraw.Draw(img)
# forests
for _ in range(14):
    x,y=random.randint(0,W),random.randint(0,H)
    pts=[(x+math.cos(a)*random.randint(80,220),y+math.sin(a)*random.randint(60,180)) for a in [i*math.pi/6 for i in range(12)]]
    d.polygon(pts,fill=(178,190,140))
# river
pts=[(-50,300+0)]
for i in range(1,12):
    pts.append((i*200, 300+math.sin(i*0.8)*180+i*70))
d.line(pts,fill=(140,170,190),width=60,joint="curve")
# towns: street grids
def town(cx,cy,n,s):
    for i in range(-n,n+1):
        d.line([(cx-n*s,cy+i*s),(cx+n*s,cy+i*s)],fill=(160,150,130),width=6)
        d.line([(cx+i*s,cy-n*s),(cx+i*s,cy+n*s)],fill=(160,150,130),width=6)
    for _ in range(n*n*3):
        bx=cx+random.randint(-n,n-1)*s+10; by=cy+random.randint(-n,n-1)*s+10
        d.rectangle([bx,by,bx+s-22,by+s-22],fill=(196,180,150))
towns=[(300,1200,4,50),(1700,350,5,45),(1750,1250,3,55),(450,350,3,45),(1100,1350,2,50)]
for t in towns: town(*t)
# highways connecting towns
for a,b in [(0,4),(4,2),(2,1),(1,3),(3,0)]:
    (x1,y1),(x2,y2)=towns[a][:2],towns[b][:2]
    mx,my=(x1+x2)/2+random.randint(-150,150),(y1+y2)/2+random.randint(-150,150)
    d.line([(x1,y1),(mx,my),(x2,y2)],fill=(200,120,90),width=14,joint="curve")
# dashed route marks with pins
for (x,y,*_) in towns:
    d.ellipse([x-22,y-22,x+22,y+22],fill=(150,40,35),outline=(60,20,15),width=5)
# vignette
v=Image.new("L",(W,H),0); vd=ImageDraw.Draw(v)
vd.ellipse([-W*0.25,-H*0.25,W*1.25,H*1.25],fill=255); v=v.filter(ImageFilter.GaussianBlur(250))
dark=Image.new("RGB",(W,H),(70,55,35)); img=Image.composite(img,dark,v)
# dim center for contrast
ov=Image.new("RGBA",(W,H),(0,0,0,0)); od=ImageDraw.Draw(ov)
od.ellipse([W/2-650,H/2-600,W/2+650,H/2+600],fill=(20,15,10,110)); ov=ov.filter(ImageFilter.GaussianBlur(120))
img=Image.alpha_composite(img.convert("RGBA"),ov)
# question mark
font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",900)
q=Image.new("RGBA",(W,H),(0,0,0,0)); qd=ImageDraw.Draw(q)
pos=(W/2-40,H/2-60)
sh=Image.new("RGBA",(W,H),(0,0,0,0)); sd=ImageDraw.Draw(sh)
sd.text((pos[0]+25,pos[1]+30),"?",font=font,fill=(0,0,0,200),anchor="mm"); sh=sh.filter(ImageFilter.GaussianBlur(25))
img=Image.alpha_composite(img,sh)
qd.text(pos,"?",font=font,fill=(180,30,25,255),anchor="mm",stroke_width=22,stroke_fill=(245,235,210,255))
img=Image.alpha_composite(img,q)
# dice
def die(cx,cy,size,ang,pips):
    t=Image.new("RGBA",(size*2,size*2),(0,0,0,0)); td=ImageDraw.Draw(t)
    o=size/2
    td.rounded_rectangle([o,o,o+size,o+size],radius=size*0.18,fill=(250,248,240,255),outline=(40,30,25,255),width=int(size*0.05))
    pr=size*0.09
    P={1:[(0.5,0.5)],2:[(0.27,0.27),(0.73,0.73)],3:[(0.27,0.27),(0.5,0.5),(0.73,0.73)],4:[(0.27,0.27),(0.73,0.27),(0.27,0.73),(0.73,0.73)],5:[(0.27,0.27),(0.73,0.27),(0.5,0.5),(0.27,0.73),(0.73,0.73)],6:[(0.27,0.25),(0.73,0.25),(0.27,0.5),(0.73,0.5),(0.27,0.75),(0.73,0.75)]}
    for px,py in P[pips]:
        x,y=o+px*size,o+py*size; td.ellipse([x-pr,y-pr,x+pr,y+pr],fill=(150,25,20,255) if pips==1 else (30,25,20,255))
    t=t.rotate(ang,resample=Image.BICUBIC,expand=False)
    s=Image.new("RGBA",t.size,(0,0,0,0)); s.paste((0,0,0,170),mask=t.split()[3]); s=s.filter(ImageFilter.GaussianBlur(14))
    global img
    img.alpha_composite(s,(int(cx-size+18),int(cy-size+22))); img.alpha_composite(t,(int(cx-size),int(cy-size)))
die(W/2+430,H/2+330,260,-18,5)
die(W/2+680,H/2+230,220,24,3)
out=img.convert("RGB")
out.resize((1024,768),Image.LANCZOS).save("random_city.png")
# square poster: crop centered on ? and dice
sq=out.crop((W//2-600,H//2-720+60,W//2+840,H//2+720+60)).resize((512,512),Image.LANCZOS); sq.save("poster.png"); sq.resize((256,256),Image.LANCZOS).save("preview.png")
sq.resize((64,64),Image.LANCZOS).save("icon.png")
