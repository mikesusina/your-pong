pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
info={
	state="menu",
	menuloc=1,
	pcount=1,
	launched=0,
	cd=85,
	intro={
		stage=1,
		delay=1.55,
		x=0, y=0,
		y2=54,
		t="●your pong●",
		cd=10,
		c=6
	},
	endinfo={
		stage=1,
		c=1
	},
	top_grav=.08,
	ball_friction=.05,
	citycount=0, --used to track gameover
	p1c=11,p2c=10
}
colorpool={3,4,6,7,10,11,12,13,15,131,134,135,138,139,140,142,143}
function newcolor(old)
	local e = old
	while (e == old) do	e = colorpool[1+flr(rnd(#colorpool))] end
	return e
end
p={}
p2={}
function newpc(slot)
	local e = {
		active=true,
		x=64, y=104, --location
		slot=slot, --p1/2 designation
		dx=0, dy=0, max_dx=2.05, max_dy=0, acc=.88,--speed and movement
		len=3, lentimer=0,--paddle length in tiles and timer
		hb={ --hitbox **w=6+len*8
			x=0,y=-1,w=12,h=2
		},
		f=1, delay=.1, --f used for color effect
		bombs=1,
		--upgrades. Next time make this a table and a checker function
		maxshot=1, wide=false, wave=false, laser=false, shottimer=0, --shot type
		shots={}, --holds pshot objects
		fast=false, fasttimer=0,
		shield=false, shieldtimer=0,
		reverse=false, revtimer=0,
		cities={{x=18,y=111,hb={x=19,y=115,w=6,h=4},alive=true, replacing=false,progress=100, f=66+flr(rnd(4))},
		{x=38,y=111,hb={x=39,y=115,w=6,h=4},alive=true, replacing=false,progress=100, f=66+flr(rnd(4))},
		{x=58,y=111,hb={x=59,y=115,w=6,h=4},alive=true, replacing=false,progress=100, f=66+flr(rnd(4))},
		{x=78,y=111,hb={x=79,y=115,w=6,h=4},alive=true, replacing=false,progress=100, f=66+flr(rnd(4))},
		{x=98,y=111,hb={x=99,y=115,w=6,h=4},alive=true, replacing=false,progress=100, f=66+flr(rnd(4))},
		},
		citycd=0, --cooldown on city damage from ball damage. probably depreciated
		stuntimer=0
	}
	return e

end

c={}
function newcpu()
	local e = {
			x=64, y=16, --location
			dx=0, dy=0, max_dx=0.95, max_dy=0, --velocity/max values
			len=3,
			acc = 1.5, 
			hb={ --hitbox
				x=0,y=-1,w=20,h=2
			},
			f=1,
			shots={},shottimer=100,maxshot=1,
			spawntimer=0,
			balltimer=30,maxballs=1,
			doors={},
			timercap=0,
			stuntimer=0
	}
	return e
end
function opendoors(type)
	local e= {f=1,t=3, type=type}
	add(c.doors, e)
end
function tickdoors()
	for d in all(c.doors) do
		d.t-=.5
		if 	(d.t<=0) then
			if (d.f+1>5) then
				if (d.type=="spawn") then
					if (flr(rnd(2))==1) then add(bumpers, newbumper(c.x+c.len*4,c.y-6))
					else add(drones, newdrone(c.x+c.len*4,c.y-6)) end
				else --d.type=="ball"
					add(balls, new_ball(c.x+c.len*3, c.y+6))
					if (#balls<c.maxballs)  c.balltimer= mid(50,30+400/((.5*max(1,info.launched+(flr(rnd(6))-3)))),250)
				end
				del(c.doors, d)
			else
				d.f+=3 d.t=3
			end
		end
	end
end

balls={}
b=nil
function new_ball(x,y)
	local e = {
		active=true,
		x=x, y=y, --location
		hb={
			x=x,y=y,w=8,h=8
		},
		h_spd=0, v_spd=0, --move speed
		f=1, delay=0.35, --frame
		cd=0, dir="d",--hit cooldown, direction
		maxspeed=1.7+.05*flr(info.launched/4),
	}
	e.h_spd=rnd(13)/10
	e.v_spd=e.maxspeed-e.h_spd
	if(1+flr(rnd(1)==1))e.h_spd*=-1
	return e
end
function kill_ball(b)
	del(balls,b)
	if (#balls==0) c.balltimer=35
	if (#balls<c.maxballs and c.balltimer<=0) c.balltimer= mid(50,30+400/((.5*max(1,info.launched+(flr(rnd(6))-3)))),250)
end

shots,dshots ={},{}
function new_pshot(p) --player/cpu shots
	local e = {
		o=p, --owner 
		x=p.x+p.len*4, y=p.y, a=.5, --a is for wave movement
		v_spd=-2, h_spd=0,
		hb={x=0, y=0, h=4,w=4},
		f=22, delay=.5,
	}
	if (p.wave) e.x-=16
--	if(p.wide) then
--		e.hb.w=30 
--		e.x=p.x+(p.len*6-e.hb.w)/2
--	end
	if(p.laser) e.y=15 e.hb.h=94 e.v_spd=0
	if(p==c) e.v_spd=1.5+(flr(info.launched/3)*.005)
	return e
end
function new_dshot(x,y) --drone shots
	local e = {
		x=x, y=y, o="d",
		acc=1,
		hb={x=x, y=y, h=4,w=4},
		f=20,
		delay=.5,
	}
	return e
end
--deletes any shot
function delshot(s)
	if(s.o==p) del(p.shots, s)
	if(s.o==p2) del(p2.shots, s)
	if(s.o==c) del(c.shots, s)
	if(s.o=="d") del(dshots, s)
end

dronemadness=false
drones={}
function newdrone(x,y)
	local e = {
		x=x, y=y,
		dx=0, dy=0,
		hp=1+(flr(info.launched/5)),
		acc=3,
		hb={x=x, y=y, h=4,w=8},
		f=36, delay=.35,
		fd=1, --value to loop back on itself
		status="wait",
		shootcd=30,
		dest={
			x=flr(rnd(108))+11,
			y=flr(rnd(67))+11
		},
	}
	set_dronedest(e)
	return e
end

bumpers={}
function newbumper(x,y)
	local e = {
		loc={x=x, y=y},
		dx=0, dy=0,
		acc=3,
		hp=1+(flr(info.launched/8)),
		hb={x=x, y=y, h=8,w=8},
		f=36, delay=.35,
		fd=1,--for warp animation direction
		status="wait",
		warpcd=30,
		angle=0,
		dest={
			x=flr(rnd(108))+11,
			y=flr(rnd(67))+11
		},
	}
	set_bumperdest(e)
	return e
end

items={}
pool = {"wide", "wave", "triple", "laser", "shield", "fast", "length", "reverse", "bomb","laser","laser","laser"} 
function newitem(x,y)
	local e = {
			state="item",
			x=x, y=y, --location
			hb={
				x=0,y=0,w=6,h=6
			},
			h_spd=0, v_spd=0, --move speed
			f=1, delay=0.35, --frame
			cd=0, --hit cooldown
			maxspeed=2.7,
		}
	e.type = pool[flr(rnd(#pool))+1]
	if (1+flr(rnd(40))>37) e.type="city"
	return e
end

explosions,ezones={},{}
--single explosion
function explode(x,y)
	local e = {
		x=x, y=y,
		f=24, delay=0.3,
		t=20,
	}
	add(explosions, e)
	sfx(13)
end
--explode a n times in an area around (x,y) (depreciated to killing the ball)
function explodezone(x,y,n)
	local e = {
		count=n,
		rate=1.5,
		cd=10,
		zone={x=x, y=y, h=5, w=5}
	}
	add(ezones, e)
	sfx(3)
end
function tick_ezone(z)
	if (z.cd-z.rate<0) then
		z.count-=1 z.cd=10
		explode(z.zone.x+(flr(rnd(z.zone.w*2))-z.zone.w),z.zone.y+(flr(rnd(z.zone.h*2))-z.zone.h))
		if (z.count==0) then
			del(ezones, z) 
		end
	end
	z.cd-=z.rate
end

texts={}
function newtext(text, x, y)
	local e = {
		text=text,x=x,y=y,
		t=30,
		c=1+flr(rnd(15))
	}
	return e
end





flash={
	active=false,
	d=true, --draw?
	r=4,
	delay=.4,
	t=0,
}
function n_flash()
	flash.active=true
	flash.r=4
	flash.t=1
	sfx(9)
end

friction=0.75

msel=1

quickboot=false
function _init()
	cls(0)
	--sfx(20)
	p=newpc(1)
	pal(3, info.p1c, 1)
	p2=newpc(2)
	pal(2, info.p2c, 1)
	poke( 0x5f2e, 1 )
	--music(0)
	if(quickboot) then new_game(2) 
	else set_gamestate("intro") end
end


function _update()
	if(info.state=="intro") then
		if (info.intro.stage==1) then
			info.intro.cd-=1
			if (info.intro.cd<65) info.intro.c=7
			if (info.intro.cd<0) info.intro.stage=2 sfx(20)
		end
		if (info.intro.stage==2) then
			if(info.intro.y< info.intro.y2) info.intro.y=min(info.intro.y2, info.intro.y+info.intro.delay) 
			if(info.intro.y>=info.intro.y2) set_gamestate("menu")
		end
	elseif (info.state=="menu") then
		if (btnp(2)) info.menuloc= max(1, info.menuloc-1)
		if (btnp(3)) info.menuloc=min(3, info.menuloc+1)
		if (info.menuloc<3 and btnp(5))  new_game(info.menuloc)

		if (info.menuloc==3) then
			if (btnp(❎,0)) info.p1c = newcolor(info.p1c) pal(3, info.p1c, 1)
			if (btnp(❎,1)) info.p2c = newcolor(info.p2c) pal(2, info.p2c, 1)
		end
	elseif (info.state=="startgame") then
		info.cd-=1
		if(info.cd<0) set_gamestate("citylanding") 
	elseif (info.state=="citylanding") then
		foreach(p.cities, city_update) --only p1 cities are ever used
		if (p.cities[5].alive) set_gamestate("game") --start on final city landing
	elseif (info.state=="game") then
		player_move(p)
		if (info.pcount==2) player_move(p2)
		cpumove()
		--if (btnp(0)) pbump()
		info.citycount=0
		foreach(p.cities, city_update) --only p1 cities are ever used
		foreach(drones, move_drone) --update the drones
		foreach(dshots, move_droneshot) --update the drone shots
		foreach(bumpers, move_bumper) --update the bumpers
		foreach(balls, ballmove) --ball movement
		--if(b.active) ballmove(b) --the ball
		foreach(items, move_item)
		foreach(ezones, tick_ezone)


		--tick visual element timers
		for e in all(explosions) do
			e.t-=1
			if ((e.t)<0) del(explosions,e)
		end
		for t in all(texts) do
			t.t-=.35
			t.y-=.25
			if(t.t<0) del(texts, t)
		end


		if (info.citycount==0) set_gamestate("gameover")
	elseif (info.state=="gameover") then
		for b in all(balls) do
			b.f+=b.delay --update frame info
			if (flr(b.f)>4) b.f=1
		end

		info.cd-=1
		if (info.cd<=0) then
			if (info.endinfo.stage<=1) info.endinfo.stage+=1 info.cd=50
			info.endinfo.c=max(1,(info.endinfo.c+1)%16)
			if (info.endinfo.stage>=2) info.cd=10
		end
		if (info.endinfo.stage>=2 and btnp(❎)) set_gamestate("menu")

	elseif (info.state=="test") then

		if (btnp(❎)) explodezone(10+flr(rnd(90)), 10+flr(rnd(90)))
		for e in all(explosions) do
			e.t-=1
			if ((e.t)<0) del(explosions,e)
		end
		foreach(ezones, tick_ezone)

	end
end


function _draw()
		cls()
		if(flash.active) then
			if(flash.d) then
				rectfill(8,8,119,14, 8)
				fillp(▒)
				rectfill(8,8,119,14, 9)
				fillp()
				rectfill(8,8,119,10, 8)
			end
			flash.t-=flash.delay
			if(flash.t<0) then
				if (flash.r%2 == 0) flash.delay=.3 flash.d=true
				if (flash.r%2 == 1) flash.delay=.45 flash.d=false
				if (flash.r-1<=0) then flash.active=false else flash.r-=1 flash.t=1 end
			end
		end

		if (info.state=="intro" or info.state=="menu") then
			if (info.state=="intro" and info.intro.stage==1) print("MADE ON A TOASTER", hcenter("MADE ON A TOASTER"), 62, info.intro.c)
			if (info.intro.stage>1) print(info.intro.t, info.intro.x, info.intro.y)
			if(info.state=="menu") then
                local cx= info.menuloc==3 and 32 or 48
                print("one P", hcenter("one P"), 64,7)
				print("two P", hcenter("two P"), 72,7)
				print("color select", hcenter("color select"), 80,7)
				print("> ", cx, 64+((info.menuloc-1)*8))
				if(info.menuloc==3) print("❎ to change", hcenter("❎ to change")-2, 88, 6)

				p.x=32
				print("P1", p.x+10, 100, 3)
				rectfill(p.x,108,p.x+24,109,3)
				if(info.menuloc>=2) then
					p2.x=72
					print("P2", p2.x+10, 100, 2)
					rectfill(p2.x,108,(p2.x+24),109,2)
				end
				
	 		end
		elseif (info.state=="startgame") then
			local s = "heed the klaxon"
			print(s, hcenter(s), 64,7)
		elseif(info.state=="citylanding") then
			local s = "heed the klaxon"
			print(s, hcenter(s), 64,7)
			for c in all(p.cities) do
				if(c.replacing) then
					spr(66,c.x, c.rep.y)
					spr(70+c.rep.f,c.x, c.rep.y+8)
				else
					spr(c.f, c.x, c.y)
				end
			end

	
		elseif (info.state=="game") then
			
			--map() --draw the map
			--?#drones
			--print("spawn: "..c.spawntimer, 30,30)
			--print("ball: "..c.balltimer, 30,38)
			--print("shot: "..c.shottimer, 30,46)
			--if (b) print(b.maxspeed, 64,73)
			draw_player(p)
			if (info.pcount==2) draw_player(p2)	
			drawcpu()
			foreach(balls, drawball)


			for s in all(dshots) do
				spr(s.f, s.x, s.y)
			end
	
			for e in all(explosions) do
				pal(4,(flr(rnd(16))+1))
				pal(9,(flr(rnd(16))+1))
				pal(10,(flr(rnd(16))+1))
				spr(e.f, e.x, e.y)		
				pal(0)
			end

			for c in all(p.cities) do
				spr(c.f, c.x, c.y)

				if(c.replacing) then
					spr(66,c.x, c.rep.y)
					spr(70+c.rep.f,c.x, c.rep.y+8)
				end
			end
	
			for d in all(drones) do
				spr(d.f, d.x, d.y)		
			end

			for d in all(bumpers) do
				if (d.status=="warpin") then  spr(d.f, d.dest.x, d.dest.y) 
				else spr(d.f, d.loc.x, d.loc.y) end		
			end
			
			for i in all(items) do
				spr(i.f+27, i.x, i.y)
				--?i.type
			end
	
			for t in all(texts) do
				print(t.text, t.x, t.y,t.c)
			end

		elseif (info.state=="gameover") then
			local s = "all is lost"
			print(s, hcenter(s), 48,7)
			if (info.endinfo.stage>=1) then
				foreach(balls, drawball)
				print(":"..info.launched, 62, 66,7)
			end
			if (info.endinfo.stage>=2) then
				local t= "❎ to rebuild"
				print(t, hcenter(t), 78, info.endinfo.c)
			end
			if (info.endinfo.stage>5) print("uh oh", 64,64,info.endinfo.c)
			--balls={new_ball(48,64)}
		end
		draw_borderui()
	end
	
	

--player functionality--
function player_move(p)
	local spd = p.acc

	if (p.stuntimer>0) then
		p.stuntimer-=1
		p.dx=0
	else
		if (p.fast) spd*=1.67
		if (p.reverse) spd*=-1
		if (btn(➡️, p.slot-1)) p.dx+=spd
		if (btn(⬅️, p.slot-1)) p.dx-=spd
	end
	--if (btnp(❎, p.slot-1)) doors("b")	opendoors("t")
	if (btnp(❎, p.slot-1)) pshot(p)
	if (not btn(❎, p.slot-1) and p.laser and #p.shots>0) foreach(p.shots, delshot)
	
	if (btnp(🅾️, p.slot-1) and p.bombs>0) then
		bomb(p)
		--opendoors("spawn")
		--set_gamestate("gameover")
		--spawn_bumper() 
		--replace_city()
	end


	local max = p.max_dx 
	if (p.fast) max*=2.33
	p.dx*=friction
	p.dx=mid(-max, p.dx,max)
	p.x+=p.dx
	p.x=mid(-1*flr((8*p.len)/2), p.x, 128-flr((8*p.len)/2))
	
	--update the hitbox
	p.hb.x=p.x
	p.hb.y=p.y
	p.hb.w=p.len*8
		
	--tick necessary upgrades
	if (p.fasttimer>0) then
		p.fasttimer-=1
		if (p.fasttimer==0) p.fast = false
	end	
	if (p.shieldtimer>0) then
		p.shieldtimer-=1
		if (p.shieldtimer==0) p.shield = false
	end	
	if (p.lentimer>0) then
		p.lentimer-=1
		if (p.lentimer==0) p.len = 3
	end	
	if (p.shottimer>0) then
		p.shottimer-=1
		if (p.shottimer==0) set_shottype(p, "base")
	end
	if (p.revtimer>0) then
		p.revtimer-=1
		if (p.revtimer==0) p.reverse=false
	end
	--and for city destruction
	if (p.citycd > 0) p.citycd-=1
	foreach(p.shots, move_playershot)

	for s in all(dshots) do
		if(collide(p,s)) then
			explode(s.x, s.y)
			delshot(s)
			sfx(10)
			p.stuntimer+=5
		end
	end
end

function pshot(p)
	if (btnp(🅾️)) return

	if(#p.shots>=p.maxshot) return
	--local s = newshot(p.slot,p.x+(p.len*4)-2, p.y-4)
	--add(p.shots, s)
	local e= new_pshot(p)
	add(p.shots, e)
	if (p.wide) then
		e=new_pshot(p)
		e.x-=12
		add(p.shots, e)
		e=new_pshot(p)
		e.x+=12
		add(p.shots, e)
	end
	sfx(1)

	--t=newtext("hey", p.x, p.y )
	--add(texts,t)
end

function bomb(p)

	for b in all(balls) do
		b.h_spd=0 b.v_spd=-3.2 b.dir="u" b.cd=7
	end
	for d in all(drones) do
		explode(d.x+4,d.y+4)
		del(drones, d)
	end
	for d in all(bumpers) do
		explode(d.loc.x+4,d.loc.y+4)
		del(bumpers, d)
	end
	
	explodezone(10+flr(rnd(100)),10+flr(rnd(100)), 1+flr(rnd(3)))
	explodezone(10+flr(rnd(100)),10+flr(rnd(100)), 1+flr(rnd(3)))
	explodezone(10+flr(rnd(100)),10+flr(rnd(100)), 1+flr(rnd(3)))
	explodezone(10+flr(rnd(100)),10+flr(rnd(100)), 1+flr(rnd(3)))

	p.bombs-=1
end

function city_update(i)
	if (i.replacing) then
		if (not i.rep) then i.rep = {f=0,y=-11} end
		i.rep.y+=1.7
		i.rep.f=(i.rep.f+1)%2
		if (i.rep.y >i.y) then
			i.alive=true i.replacing=false i.rep=nil 
			if (not info.state=="citylanding") 	explodezone(i.x,i.y,3)
		end
	elseif (not i.alive) then
		i.progress+=0.05
		i.f=85
		if (i.progress>25) i.f=84
		if (i.progress>50) i.f=83
		if (i.progress>75) i.f=82
		if (i.progress>=100) i.f=66+flr(rnd(4)) i.alive=true --sfx?
		return
	else 
		if (i.f+.04>=70) i.f=66
		i.f+=0.04
		local dead = false
		if(collide(i,b) and p.citycd==0) dead=true p.citycd = 75
		if(#c.shots>0) then
			for s in all(c.shots) do 
				if (collide(i,s)) dead=true
			end
		end
		for b in all(balls) do
			if (collide(i,b)) dead=true explodezone(b.x+4, b.y+4, 4) kill_ball(b) 
		end
		for d in all(dshots) do
			if (collide(i,d)) dead=true
		end
		info.citycount+=1

		if(dead) explode(i.x+4, i.y+2) i.alive=false i.progress=0 sfx(12)
	end
end

function p_upgrade(p, o)
	if (o.type=="wide") set_shottype(p,o.type)
	if (o.type=="wave") set_shottype(p,o.type)
	if (o.type=="triple") set_shottype(p,o.type)
	if (o.type=="laser") set_shottype(p,o.type)
	if (o.type=="shield") p.shield=true p.shieldtimer = 350
	if (o.type=="fast") p.fast = true p.fasttimer = 600
	if (o.type=="bomb") p.bombs+=1
	if (o.type=="city") replace_city()
	if (o.type=="length") p.len=5 p.lentimer=600
	if (o.type=="reverse") p.reverse=true p.revtimer=300

	t=newtext(o.type, p.x, p.y )
	add(texts,t)
	del(items,o)
	sfx(5)
end
function set_shottype(p, type)
	p.wide=false p.laser=false p.wave=false p.maxshot=1
	foreach(p.shots, delshot)
	if (type=="base") return
	if(type=="wide")p.wide=true
	if(type=="laser")p.laser=true
	if(type=="wave")p.wave=true
	if(type=="triple")p.maxshot=3
	p.shottimer=450
end

function replace_city()
	local c = get_city(false)
	if (not c) return
	c.replacing=true
	c.rep = {f=0,y=-11}
end

--ball functionality--
function ballmove(b)
	if(b.cd>0)b.cd=max(0,b.cd-1) --iframe
	b.f+=b.delay --update frame info
	if (flr(b.f)>4) b.f=1
    if (b.y<8) b.v_spd+=info.top_grav--gravity once off screen
    if (b.y<8 and b.y+b.v_spd>=0) b.dir="d" --flip ball direction if gravity pulls if back onscreen 
    
	--apply friction to y-movement above the ball max
	if (abs(b.v_spd)>b.maxspeed) b.v_spd = (b.v_spd>0) and b.v_spd-info.ball_friction or b.v_spd+info.ball_friction 
	--commit the movement
	b.x+=b.h_spd
	b.y+=b.v_spd

	--side wall interaction
	if (b.x<8 or b.x>110) b.h_spd*=-1
	b.x = mid(8,b.x,110)
	--ceiling/flr interaction
	local floor = 119
	if(p.shield or p2.shield)floor=109
	if (b.y<-20 or b.y+b.hb.h>floor) then
		b.v_spd*=-1
		if (b.y<=-20) then 
			launch_ball(b)
			b.dir="d"
		else
			b.dir="u"
		end
	end
	b.y = mid(-20,b.y,120)
	
	--update the hitbox
    b.hb.x,b.hb.y=b.x,b.y
	--collisions
	if (b.cd==0) then
		if (b.dir=="d") then
			local tap = false
			if(collide(b,p) and b.y<p.y) ball_ping(p,b) tap=true --p1 paddle
			if(info.pcount==2 and collide(b,p2) and b.y<p2.y and not tap) ball_ping(p2,b) --p2 paddle
		end
		if(b.dir=="u" and collide(b,c)) ball_ping(c,b)  --cpu paddle

		for d in all(bumpers) do
			if (d.status=="hover" and collide(b,d))then
				b.h_spd = ((rnd(10)-5)/10) b.v_spd = 2.1+flr(info.launched/5)/10
				b.cd=5 b.dir="d"
				sfx(21)
			end
		end
	end
end

function ball_ping(p, b)
	b.cd=10
	b.maxspeed+=.07
	local offset = (b.x - ((p.len*8/2) + p.x))
	local phi = (0.25)*(3.14)*(2*offset-1)

    b.h_spd = b.maxspeed * sin(phi)
	b.v_spd *= -1
	b.v_spd = b.v_spd>0 and b.v_spd+rnd(9+flr(info.launched/3))/10 or b.v_spd-rnd(9+flr(info.launched/3))/10
	--direction flag
	b.dir = p==c and "d" or "u"
	sfx(10)
end

function launch_ball(b)
	info.launched+=1
	n_flash() 
    kill_ball(b)
	c.maxballs=1+flr(info.launched/5)
	c.maxshot=1+flr(info.launched/5)

end

--pshot actions--
function move_playershot(s) --player shots update
	s.x+=s.h_spd
	s.y+=s.v_spd

	if (s.o.wave) then
		s.a+=.045
		s.h_spd=sin(s.a)*4.5
		s.v_spd= max(-2.1*abs(cos(s.a)),-4)
	end
	s.hb.x = s.x+2
	if(s.o.laser) s.x=s.o.x+s.o.len*4-4 s.hb.x=s.x+4
	s.hb.y = s.y
	
	s.f+=s.delay
	if(s.f>23) s.f=22
	if (collide(s, c)) shootpaddle(s,c)
	
	for b in all(balls) do
		if (collide(s,b)) shootball(s,b)
	end
	--if (collide(s, b) and b.active) playershot_hit(s, b)

	for d in all(drones) do
		if (collide(s,d)) shootdrone(s,d)
	end
	for d in all(bumpers) do
		if (d.status=="hover" and collide(s,d)) shootbumper(s,d)
	end

	if (s.y<0 or s.y>128 or s.x>160 or s.x<-32) del(s.o.shots, s)
end

function shootpaddle(s, o)
    --stun paddle
    local e = true
	local t =(s.o.laser) and 1.5 or 25
	--limit the explosion effects from the laser
	if (s.o.laser and rnd(10)<9.6) e = false 
    if (e) explode(s.x+s.hb.w/2, s.y)
	if (not s.o.laser) delshot(s)
	o.stuntimer=min(100,o.stuntimer+t)
end

function shootball(s,b)
	local e = true
	--limit the explosion effects from the laser
	if (s.o.laser and rnd(10)<9.6) e = false 
	if(e) explode(s.x+s.hb.w/2, s.y)

    local spd = -4.2+(-1*b.v_spd)
	if (s.o.laser) spd = -1*abs(spd) 
    b.v_spd+=spd
    if (b.v_spd<0) b.dir="u"
    --if (s.o.laser) then o.v_spd-=.065
    --else o.v_spd = -3.5 end
    if (s.o.laser==false) b.h_spd = 0
	if (not s.o.laser) delshot(s)
end

function shootdrone(s,d)
	local dmg,ex=1,true
	if (s.o.laser) then 
		dmg=100
		if (1+rnd(100)<95) ex=false
	end
	d.hp-=dmg
	if(d.hp<=0) then
		ex=true
		if(1+rnd(100)<(33+400/info.launched)) then
			local i = newitem(d.x+4, d.y+4)
			i.v_spd=-1.3
			i.h_spd=(rnd(6)-3)/10
			add(items, i)
		end
		del(drones,d)
	end
	if (ex) explode(d.x+4, d.y+4)
	if (not s.o.laser) delshot(s)
end

function shootbumper(s,b)
	local dmg,ex=1,true
	if (s.o.laser) then 
		dmg=100
		if (1+rnd(100)<95) ex=false
	end
	b.hp-=dmg
	if(b.hp<=0) then
		ex=true
		if(1+rnd(100)<(33+400/info.launched)) then
			local i = newitem(b.loc.x+4, b.loc.y+4)
			i.v_spd=-1.3
			i.h_spd=(rnd(6)-3)/10
			add(items, i)
		end
		del(bumpers,b)
	end
	if (ex) explode(b.loc.x+4, b.loc.y+4)
	if (not s.o.laser) delshot(s)
end


--cpu/drone actions--
function cpumove()
	if (c.stuntimer>0) then
		c.stuntimer=max(0, c.stuntimer-1)
	else
		--get the closest ball the paddle might hit:
		local topb = nil
		for b in all(balls) do
			if (topb==nil) topb=b
			if ((b.v_spd<0) and (topb.y > b.y and b.y > c.y)) topb=b
		end
	
		if (topb) then
			if(c.x+flr(c.len*8/2) > topb.x+4) c.dx=c.acc*-1
			if(c.x+flr(c.len*8/2) < topb.x+4) c.dx=c.acc
			if(topb and topb.v_spd>0) then
				c.dx=0
				if (c.x<35) c.dx=c.acc
				if (c.x>98) c.dx=c.acc*-1
			end
			if (abs(c.x+(c.len*8/2) - topb.x+4) <=2) c.dx=0
			c.x+=c.dx
		elseif (c.x<33 or c.x>95) then
			c.dx= c.x<33 and c.acc or (c.acc*-1)
		end
	end
	
	c.hb.x=c.x -- -flr(p.hb.w/2)
	c.hb.y=c.y -- -flr(p.hb.h/2)
	c.hb.w=c.len*8
	if (#balls<c.maxballs) then
		if(c.balltimer>0) then
			c.balltimer-=1
			if (c.balltimer<=0) opendoors("ball")
		end
	end

	c.shottimer = max(c.shottimer-1, 0)
	if(#c.shots<c.maxshot and c.shottimer<=0) then
		--if (rnd(100)>mid(30, 106-info.launched*3, 95)) add(c.shots, new_pshot(c))
		add(c.shots,new_pshot(c))
		c.shottimer= mid(75,30+650/max(1,(info.launched+(flr(rnd(6))-3))), 325)
	end

	--deffo raise min spawn timer
	--ADDITIONAL reduction of spawn chance with more active drones and bumpers (maybe have a cap?) 
	c.spawntimer = max(c.spawntimer-1, 0)
	if(c.spawntimer==0) then
		local dip = flr((#drones+#bumpers)/2)
		if(rnd(100)>max(40, 85-flr((info.launched-dip)/3)*3)) opendoors("spawn")
		c.spawntimer=mid(65, 40+(175/max(1,(info.launched+(flr(rnd(6))-3)))), 275)
	end


	for s in all(c.shots) do
			s.x+=s.h_spd
			s.y+=s.v_spd
			s.hb.x = s.x+2
			s.hb.y = s.y+4
			s.f = s.f+s.delay>23 and 22 or s.f+s.delay
			if (collide(s, p))  explode(s.x+s.hb.w/2, s.y) delshot(s) sfx(11) p.stuntimer+=15
 			if (info.pcount==2 and (collide(s, p2)))  explode(s.x+s.hb.w/2, s.y) delshot(s) sfx(11) p2.stuntimer+=15
			if ((s.y<0) or s.y>128) delshot(s) 
	end
	tickdoors()

end

function move_drone(d)
	d.f+=(d.delay*d.fd)
	if(d.f>=40 or d.f <= 36) then
		d.fd*=-1
		d.f= mid(37,d.f, 39)
	end
	
	if(d.status=="end") set_dronedest(d)
	
	if (d.status == "move") then
		local m=.7
		local dx = abs(d.x-d.dest.x)
		local dy = abs(d.y-d.dest.y)
		d.dx=0
		d.dy=0
		if (dx>dy) then 
			d.dy=m*(dy/dx)
			d.dx=m*(1-dy/dx)
		else
			d.dy=m*(1-dx/dy)
			d.dx=m*(dx/dy)
		end
		if (d.x>d.dest.x) d.dx*=-1
		if (d.y>d.dest.y) d.dy*=-1
		
		d.x+=d.dx
		d.y+=d.dy
		if ((dx+dy)<6) then
			d.dest.x=d.x+5
			d.status="hover"
		end
	elseif (d.status=="hover") then
		d.dx=0.4
		if (d.x>d.dest.x) d.dx*=-1
		d.dy=0		 
		if (abs(d.x-d.dest.x)<2) then --on approaching x destination, shift to hover
			if(d.x-d.dest.x<0) then d.dest.x=d.x-10
			else d.dest.x=d.x+10 end
		end

		if(flr(1+rnd(300))==300) set_dronedest(d)
		d.x+=d.dx
	end
	if(d.shootcd>0) d.shootcd-=1
	if(d.shootcd==0) then
		--local e =   
		--{acc=1, hb={x=x, y=y, h=4,w=4}, f=20, delay=.5}
		if ((1+flr(rnd(100)))>=(75-flr(info.launched/3)*2)) add(dshots,new_dshot(d.x+2, d.y+4)) sfx(2)
		--newshot(4,d.x+4,d.y+4)) sfx(2)
		 d.shootcd = 40+200/max(1,info.launched+(flr(rnd(6))-3))
	end
	d.hb.x=d.x
	d.hb.y=d.y+2
		
end

function set_dronedest(d)
		d.dest={
			x=flr(rnd(108))+11,
			y=flr(rnd(67))+11
		}
		local i = get_city(true)
		if (rnd(1)*100>75 and i) d.dest.x=i.x
	d.status="move"
end

function move_droneshot(d)
	d.f+=d.delay
	if(d.f>21) d.f=20
	d.y+=.5+(flr(info.launched/4)/10)
	d.hb={x=d.x+2, y=d.y+2, h=2,w=2}

	-- explode on shield
	if((p.shield or p2.shield) and d.hb.y+d.hb.h>109) then
		explode(d.x, d.y)
		delshot(d)
		sfx(10)
		return
	end
	--player paddle blocks shots is in player movement 

	if(d.y>128) delshot(d)

end

function spawn_bumper()
	local e = newbumper(44,44)
	set_bumperdest(e)
	e.status="hover"
	e.f=40
	e.loc=e.dest
	e.warpcd=10
	e.fd=1
	add(bumpers,e)
end
function move_bumper(d)
	d.f+=(d.delay*d.fd)
	if (d.status=="hover") then
		if(d.f>=44) d.f=40
		d.warpcd-=1
		if (d.warpcd<0) then set_bumperdest(d)
		else
			d.angle+=.03
			if (d.angle>1) d.angle=0
			d.loc.x = d.dest.x+.5*cos(d.angle)  
			d.loc.y = d.dest.y+.5*sin(d.angle)
		end
	end
	if (d.status=="warpout" and d.f>107) d.status="warpin"  d.fd=-1
	if (d.status=="warpin" and d.f<103) d.status="hover" d.fd=1 d.delay=.25 d.f=40 d.warpcd=100 d.loc=d.dest
		

	d.hb.x=d.loc.x
	d.hb.y=d.loc.y

	--ball collision
	--if (d.status=="hover" and collide(d, b))
end
function set_bumperdest(d)
	d.dest={
		x=flr(rnd(108))+11,
		y=flr(rnd(47))+35
	}
	local i = get_city(true)
	if (rnd(1)*100>35 and i) d.dest.x=i.x
	d.status="warpout"
	d.f=103
	d.fd=1
	d.delay=.065
	
end

--item stuff--
function move_item(b)
	b.f+=b.delay
	
	if (flr(b.f)>4) b.f=1
	b.x+=b.h_spd
	b.y+=b.v_spd

	if (b.x<0 or b.x>120) b.h_spd*=-1
	b.x = mid(0,b.x,120)
	if (b.y<0 or b.y>120) b.v_spd*=-1
	b.y = mid(0,b.y,120)
	
	--the hitbox
	b.hb.x=b.x+1
	b.hb.y=b.y+1


	if(collide(b,p)) p_upgrade(p,b)
	if (collide(b,p2)) p_upgrade(p2,b)
	if(collide(b,c)) ball_ping(c,b)
end


--level/menu/gamestate scripts
function set_gamestate(state)
	if(state=="intro") begin_intro()
	if(state=="citylanding") then
		local i = 1
		while (i<=#p.cities) do
			p.cities[i].alive=false
			p.cities[i].replacing=true
			p.cities[i].rep = {f=0,y=-11-(i*12)}
			i+=1
		end
	end
	--if(state=="menu")
	if(state=="startgame") sfx(15,2)
	if(state=="game") sfx(-1) 
	if(state=="gameover") game_over()
	info.state=state
end

function new_game(count)
	--create the new players
	info.pcount=count
	p=newpc(1)
	p2.active=false if (count==2) p2=newpc(2)
	c = newcpu() --reset the cpu
	info.launched=0 --set to zero as new level bumps it up one
	balls,drones,dshots,items,explosions,texts={},{},{},{},{},{}
	info.cd=70 --setting timer to display level # screen{}
	set_gamestate("startgame")
end


function game_over()
	balls={new_ball(52,64)}
	info.endinfo.stage=0
	info.cd=50
	sfx(20)
end

function begin_intro()
	--reset the intro script stuff
	info.intro.x=hcenter(info.intro.t)-6
	info.intro.y=-8
	info.intro.stage=1
	info.intro.cd=75
	info.intro.c=6
end





--draw functions--
function draw_player(o)
	local oc = o.slot==1 and 3 or 2
	rectfill(o.x, o.y, o.x+(8*o.len), o.y+1, oc)
	--pal()
	if (o.x<7) then
		for i=o.x,8 do
			pset(i,o.y+3,0)
			pset(i,o.y+4,0)
		end
	end
	if (o.x+o.len*8>100) then
		for i=o.x+o.len*8, 119, -1 do
			pset(i,o.y+3,0)
			pset(i,o.y+4,0)
		end
	end

	if(o.shield) line(11,(109+o.slot),118,(109+o.slot),(10-o.slot))

	for s in all(o.shots) do
		spr(s.f, s.x, s.y)
		if (o.laser) then
			if (not s.lf) s.lf=0
			local i=s.y+8
			clip(0,0,128,128-(128-o.y)+2)
			while (i<o.y) do
				spr(96+s.lf, s.x, i)
				s.lf=(s.lf+1)%4
				i+=8
			end
			clip()
		end
		--rect(s.hb.x, s.hb.y, s.hb.x+s.hb.w, s.hb.y+s.hb.h)
	end
end


function drawcpu()
	
	rectfill(c.x, c.y, c.x+(c.len*8), c.y+1, 8)
	if (c.x<7) then
		for i=c.x,8 do
			pset(i,c.y+3,0)
			pset(i,c.y+4,0)
		end
	end
	if (c.x+c.len*8>100) then
		for i=c.x+c.len*8, 119, -1 do
			pset(i,c.y+3,0)
			pset(i,c.y+4,0)
		end
	end

	if(#c.shots>0) then
		for s in all(c.shots) do 
			pal(15,8)
			pal(4, 2)
			pal(1,9)
			pal(12,10)
			spr(s.f, s.x, s.y, 1,1,false,true)
			pal(0)
		end
	end
	
	for d in all (c.doors) do
		if (d.type=="spawn") then
			line(c.x + c.len*2, c.y-1, c.x + c.len*4-ceil(d.f*1.25)+2, (c.y-1)-(flr(d.f/2)),8)
			line(c.x + c.len*6,	c.y-1, c.x + c.len*4+ceil(d.f*1.25)-2, (c.y-1)-(flr(d.f/2)),8)
		else --=="ball"
			line(c.x, c.y+2, c.x+(c.len*4-(d.f*2)),  c.y+(3+(d.f*2)),8)
			line(c.x+c.len*8-1, c.y+2, c.x+c.len*4+(d.f*2)-1, c.y+(3+(d.f*2)),8)

		end

	end
end

function drawball(b)
	local ballf = 5 --1-state frame
	if (b.state=="transform") ballf= 55
	if (b.state=="teleport") ballf= 102
	if (b.state=="weak") ballf=39
	spr(b.f+ballf, --draw the ball
		b.x, b.y, --x,y
		1,1, --w,h
	false,false --flip x,y
		)



end

uiballf=0
function draw_borderui()
	color(11)
	--border rects
	rect(0,0,127,127) --outer
	rect(9,8,118,119)--inner
	--player upgrades

	if (info.state=="game") then
		uiballf=(uiballf+.35)%4
		--if(uiballf>=122) uiballf=119
		spr(119+uiballf, 54, 1)
		print(":"..info.launched, 64,2)
		draw_playerupgrade(p)
		if(info.pcount==2) draw_playerupgrade(p2)
		--launched:
		
		--if (info.state == "game") if (info.pcount==2) print("points: "..p2.points, 60,2)
		--if (info.state == "game") print("points: "..p.points, 5,2)
		--bombs
		print("bombs: "..p.bombs, 5,121)
		if (info.pcount==2) print("bombs: "..p2.bombs, 80,121)
	end
	color()
end


function draw_playerupgrade(p)
	local x=1
	local y=22
	if (p.slot==2) x=119

	local color = 6
	for i=0, 6 do
		color = 6
		if(i==0 and p.maxshot==3) color = 12
		if(i==1 and p.wave) color = 12
		if(i==2 and p.wide) color = 12
		if(i==3 and p.laser) color = 12
		if(i==4 and p.shield) color = 12
		if(i==5 and p.fast) color = 12
		if(i==6 and p.reverse) color = 12
		pal(6, color)
		spr(112+i, x, y+i*12)
		pal(0)
	end
end








--misc--

function collide(o1, o2)
	if (not o1) return
	if (not o2) return
	local xd = abs((o1.hb.x + flr(o1.hb.w/2)) - (o2.hb.x + flr(o2.hb.w/2)))
	local xs = flr(o1.hb.w/2) + flr(o2.hb.w/2)
	local yd = abs((o1.hb.y + flr(o1.hb.h/2)) - (o2.hb.y + flr(o2.hb.h/2)))
	local ys = flr(o1.hb.h/2) + flr(o2.hb.h/2)

 if xd<xs and 
    yd<ys then 
   return true 
 end
 
 return false
end

function get_city(living)
	local ool = {}
	for c in all(p.cities) do
		if (c.alive==living) add(ool, c)
	end
	local e = nil
	if (#ool>0) e = ool[1+flr(rnd(#ool))]
	return e
end

function hcenter(s)
	-- screen center minus the
	-- string length times the 
	-- pixels in a char's width,
	-- cut in half
	return 64-#s*2
end

__gfx__
0000000000077000000770000007700000077000000000000088880000888800008888000088880000000000333333333333333333333333dddddddd00000000
0000000000700700007007000070070000700700000000000811a18008111180081111800811118000000000334333333333333333555333d666566d00000000
007007000070070000700700007007000070070000000000811a111881a11a188111a11881a11a1800000000345334333333333333333353d666656d00000000
00077000077777700007700070077007777777770000000081aaa118811aa1188a1aaa18811aa11800000000333333333333333333333333d666666d00000000
000770007007700707777770077777700007700000000000811aaa18811aa11881aaa1a8811aa11800000000333343333333333333333333d666666d00000000
0070070000077000000770000007700000077000000000008111a11881a11a18811a111881a11a1800000000333333543333333333343333d566666d00000000
000000000070070007700770077007700070070000000000081a118008111180081111800811118000000000334335433333333334433333d656666d00000000
0000000077000077700000077000000707700770000000000088880000888800008888000088880000000000333333333333333333333333dddddddd00000000
000000000000000000000000000000000000000000000000044004400440044000090a040a009000a400049909000440000000000000000000c00c0000b00b00
0000000000000000777777777777777700000000000000004ff44ff44ff44ff449009090a40000090000a009000a0090000cc00000b00b00000cc00000000000
00000000333333330000000033333333000000000080080004ffff4004ffff4000a000a00009040000a000000000000000cbbc000bbccbb0c0cbbc0cb00cc00b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00088000000aa00004ffff4004ffff4004000990900aa000090000a00a090a000cbccbc000cbbc000cbccbc000c00c00
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00088000000aa0000444444004444440099009009004a000990400aa000000000cbccbc000cbbc000cbccbc000c00c00
00000000333333330000000033333333000000000080080000c00c00000cc000a000a00900000900000000004000090000cbbc000bbccbb0c0cbbc0cb00cc00b
000000000000000077777777777777770000000000000000010cc010001cc100000900400a09990990a000a0000a0000000cc00000b00b00000cc00000000000
00000000000000000000000000000000000000000000000000c00c00000cc00009009900900000a00900a40009000040000000000000000000c00c0000b00b00
00000000000000000000000000000000000000000000000000000000000000000000000000000000008888000000000000000000000000000000600000006000
000070000000000000000007000070770000000000000000001001000000000000000000008888000e8118e00880088000000000000660000066600000000600
00007a00000000700000007300000773000000000010010000099000001001000088880008111180eeeeeeeee8e88e8e00000000006006000060000006666660
0070a900000000030000000300000733001001000989989099899899000990000e8118e0ee1111ee0ee00ee0eee11eee00000000000660000060660000000000
0077670000000003000000030000073300899800900990090009900090099009eeeeeeeeeeeeeeee0e0000e00eeeeee000000000060000600066060000006000
a9777707000000700000007300000773090990900009900000000000098998900ee00ee00eeeeee0eee00eee00e00e0000000000606006060000060000000600
9777777700000000000000070000707790099009000000000000000000000000ee0000ee0eeeeee00ee00ee00ee00ee000000000060000600006660006666660
7777777700000000000000000000000000000000000000000000000000000000ee0000ee00e00e00000000000000000000000000000000000006000000000000
00000000000000000000000000000000000000000000000000044000000440000088880000888800008888000008800000000000000000000000000000000000
000070000000700000000000000000000000000000000000004ff000004ff0000811218008122180081221800822228000066600006006000099990006666600
00007a000000770000000700000000000000000000000000044ff400044ff4008112111881222218812222188821128800600000060000600886688000600660
0070a90000707a00000076000000060000000000000000004fffff404fffff4081aaa11881122118811221180812218006006600666666660668866000600060
007799000077a90000006d0000006d0000000600000000004fffff404fffff40811aaa18811aaa18811aaa188818818806060060666666660668866000666600
7a776707777767077007d7000000d7070000d70000070000004ff4c1004ff4108111a1188111a118888888888888888806000060060000600886688000600660
a97777777a7777777677770776777777000777770007700000044c0c000441c1081a118008188180888008888000000800600600006006000099990006600660
99777777a977777765777777657777776577777760770777000001c00000001c0088880000800800080000800000000000066000000000000000000000000000
00000000000000000000000000000000000000000000000000a99a0009aaaa9009aaaa900a9aa9a0000000000000000000000000000000000000000000000000
0000000000000000000070000000700000007000000070000a99a9a0009aa900009aa900a999999a000000000000000000000000000000000000000000000000
00000000000000000000770000007a0000007a00000079000a9a99a000a99a0000a99a00a9999a9a000000000000000000000000000000000000000000000000
000666666666666600707a000070a9000070a900007067000a99a9a009aaaa9009aaaa90a99a999a000000000000000000000000000000000000000000000000
00655555555555550077a90000779600007767000077770000a99a0000099000000990000a9999a0000000000000000000000000000000000000000000000000
0655555566666565777797077a776707a977770796777a07000aa000000000000000000000a99a00000000000000000000000000000000000000000000000000
06555555555555557a777777a9777777967777777777a777a00000a00000000000000000000aa0a0000000000000000000000000000000000000000000000000
6555555555555555a977777796777777777777777a77777700a0000000000000000000000a000900000000000000000000000000000000000000000000000000
06555755555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06555555555555550000000000000000000000000000000000000000000000000022220000000000000000000000000000000000000000000000000000000000
06555555555555550000070000000000000000000000000000000000002222000211112000000000000000000000000000000000000000000000000000000000
06557555555555550000760000000600000000000000000000000000082112808811118800000000000000000000000000000000000000000000000000000000
065557555555555500006d0000006d00000006000000000000000000888888888888888800000000000000000000000000000000000000000000000000000000
00655555555555557007d7000000d7070000d7000007000000000000088008800888888000000000000000000000000000000000000000000000000000000000
00666666777777777677770776777777000777770007700000000000880000880888888000000000000000000000000000000000000000000000000000000000
00000000666666666577777765777777657777776077077700000000880000880080080000000000000000000000000000000000000000000000000000000000
001cc100001cc10000cccc0000cccc00000000000000000000000000000000000000000000000ee0000000000000000000000000000000000000000000000000
001cc100001cc10000cccc0000cccc00000000000000000000000000000eee000880eeee88000000ee0000000000000000000000000000000000000000000000
001cc10000cccc0000cccc00001cc100000000000000000000000000e0110880081100eee1ee000000000e100000000000000000000000000000000000000000
001cc10000cccc0000cccc00001cc1000000000000000000000000000881100e0eee0118000001100ee000000000000000000000000000000000000000000000
001cc10000cccc00001cc100001cc100000000000000000000000000eeeeeeeeeee0008800000e88000000000000000000000000000000000000000000000000
00cccc0000cccc00001cc100001cc1000000000000000000000000000ee00ee00ee00eee000eeeee0eee00000000000000000000000000000000000000000000
00cccc00001cc100001cc10000cccc00000000000000000000000000e0ee00ee0000eee000000000000eee000000000000000000000000000000000000000000
00cccc00001cc100001cc10000cccc000000000000000000000000000e00eee0eee000000ee00eee000000000000000000000000000000000000000000000000
00066000000060000000000000666600000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000600000000000000d66d00066666600000060006666600008888000088880000888800008888000000000000000000000000000000000000000000
00000000006000000000000000566500066600600666666000600660081a118008a11a800811a18008a11a800000000000000000000000000000000000000000
0006600000606000066666600056650006666060000000000060006008aaa180081aa18008aaa180081aa1800000000000000000000000000000000000000000
00066000000606006555555600566500006666000000600000666600081aaa80081aa180081aaa80081aa1800000000000000000000000000000000000000000
000000000000060006666660005665000066660000000600006006600811a18008a11a80081a118008a11a800000000000000000000000000000000000000000
00066000000060000000000000d66d00000660000666666006600660008888000088880000888800008888000000000000000000000000000000000000000000
00066000000600000000000000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000000000000000003333333300000000000000000000000000000000
dddddddddddddddddddddddd000000000000000000000000dddddddddddddddd0000000000000000333333333333333333333333000000000000000000000000
dddddddddddddddddddddddd00000000dddddddd00000000dddddddddddddddd0000000000000000333333333333333333333333000000000000000000000000
dddddddd00000000dddddddddddddddd0000000000000000dddddddddddddddd3333333300000000000000003333333333333333000000000000000000000000
dddddddddddddddddddddddd0000000000000000dddddddd00000000000000000000000000000000333333333333333300000000333333333333333300000000
dddddddd0000000000000000dddddddd00000000dddddddd00000000000000003333333333333333000000003333333300000000333333333333333300000000
dddddddddddddddd00000000dddddddd0000000000000000dddddddddddddddd0000000033333333000000003333333333333333000000000000000000000000
dddddddddddddddd00000000dddddddd00000000dddddddddddddddddddddddd0000000033333333000000003333333300000000000000000000000000000000
dddddddddddddddddddddddd000000000000000000000000dddddddddddddddd0000000033333333333333330000000033333333000000000000000000000000
dddddddd00000000dddddddd00000000000000000000000066666666666666660000000033333333000000000000000000000000666666666666666600000000
dddddddd000000000000000000000000000000000000000000000000000000000000000055555555333333333333333300000000333333333333333300000000
dddddddddddddddddddddddddddddddd0000000000000000dddddddddddddddd0000000000000000333333333333333333333333000000000000000000000000
dddddddddddddddddddddddd000000000000000000000000dddddddddddddddd0000000033333333333333333333333333333333000000000000000000000000
dddddddddddddddd000000000000000000000000dddddddd66666666666666660000000000000000333333333333333333333333666666666666666600000000
dddddddddddddddddddddddddddddddddddddddd0000000000000000000000003333333300000000000000003333333333333333333333333333333300000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd3333333300000000333333330000000033333333000000000000000000000000
dddddddddddddddddddddddd00000000dddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd00000000dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd00000000dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd00000000dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddd0000000000000000dddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddd00000000dddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000bbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000bbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000
0000070000333000000000000000000000000000000000000000aaaabbbbbb000000000000000000000000000000000000000000000000000000000000000000
0000004333999933000000000000000000000000000000000000aaaabbbbbb000000000000000000000000000000000000000000000000000000000000000000
00070739999399993000000000000000000000000000000000000000aaaabbbbbb00000000000000000000000000000000000000000000000000000000000000
00004399933999938888333300000000000000000000000000000000aaaabbbbbb00000000000000000000000000000000000000000000000000000000000000
000039399999393888883993300000000000000000000000000000000000aaaabbbbbb0000000000000000000000000000000000000000000000000000000000
000439993993000888889999330000000000000000000000000000000000aaaabbbbbb0000000000000000000000000000000000000000000000000000000000
0004393999300008888399999333000000000000000000000000000000000000aaaabbbbbb000000000000000000000000000000000000000000000000000000
0004399993300000888999999993300000000000000000000000000000000000aaaabbbbbb000000000000000000000000000000000000000000000000000000
00004399930000000039919999993000000000000000000000000000000000000000aaaabbbbbb00000000000000000000000000000000000000000000000000
00000399300000000999999999993000000000000000000000000000000000000000aaaabbbbbb00000000000000000000000000000000000000000000000000
000049993000000009919119199388000000000000000000000000000000000000000000aaaaabbbbbb000000000000000000000000000000000000000000000
000049930000000039999999999888833000000000000000000000000000000000000000aaaaabbbbbb000000000000000000000000000000000000000000000
00004393000000003999991999888889933300000000000000000000000000000000000000000aaaabbbbbb00000000000000000000000000000000000000000
00000430000007739199999993888899993993470000000000000000000000000000000000000aaaabbbbbb00000000000000000000000000000000000000000
000000430000773911999999900888399993934000000000000000000000000000000000000000000aaaabbbbbb0000000000000000000000000000000000000
000000000007760399999999300000039393993707000000000000000000000000000000000000000aaaabbbbbb0000000000000000000000000000000000000
0000000000077600399911990000000399993934440000000000000000000000000000000000000000000aaaabbbbaa000000000000000000000000000000000
0000000000076000099919930000003399999934400000000000000000000000000000000000000000000aaaabbbbaa000000000000000000000000000000000
00000000000760000099993000000039939999334000000000000000000000000000000000000000000000000aaaaaa000000000000000000000000000000000
00000000000070000009993000000009999993440000000000000000000000000000000000000000000000000aaaaaa000000000000000000000000000000000
00000000000006000000337000000003999393400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000677000000003999933400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006006777000000003999334000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000777770000000009999340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077700000000039993400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000039993400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000030333444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000004444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000007770700070000000777007700000700007700770777000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000007070700070000000070070000000700070707000070000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000007770700070000000070077700000700070707770070000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000007070700070000000070000700000700070700070070000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000007070777077700000777077000000777077007700070000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000008888000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000081111800000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b00000000000000000000000000000000000000000081a11a180000007700000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000811aa1180007000700000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000811aa1180000000700000000000000000000000000000000000000000000000000b00000000b
b00000000b00000000000000000000000000000000000000000081a11a180007000700000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000081111800000007770000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000008888000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000088888000000888008800000888088808880808088808000880000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000880808800000080080800000808080008080808008008000808000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000888088800000080080800000880088008800808008008000808000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000880808800000080080800000808080008080808008008000808000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000088888000000080088000000808088808880088088808880888000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b
b00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

__map__
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c000000000000000000000000000000008b8b8b8b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c000000000000000000000000000000008b8b8b8b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0b0b0c0c0c0c0b0c0d0c0c0c0c0c0c00000000000000000000000000000000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0d0b0b0c0b0b0c0c0c0c0c0b0c00000000000000c0c1c2c3c4c50000008c8c8c8c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0b0b0d0c0c0c0c0d0c8200000000000000d0d1d2d3d4d50000008b8b8b8b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0c0c0c0c0c0d0c0c0c0c00000000000000e0e1e2e3e4e50000008a8a8a8a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0d0c0c0c0c0d0c0c0c0c0c0d0c00000000000000f0f1f2f3f4f500000082828b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0d0e0e0e0e0e0e0e0e0e00000000000000000000000000000000838300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0d0c0c0c0c0c0e0e0e0e0e0e0e0e0e000000000000000000000000000000009b9b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0b0c0c0c0e0e0e0e0e0e0e0e0e00000000000000000000000000000000999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0d0c0c0e0e0e0e0e0e0e0e0e0000c6c7c8c9cacb00000000000000009d9d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0d0c0c0c0c0e0e0e0e0e0e0e0e0e0000d6d7d8d9dadb00000000000000009b9b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0d0c0e0e0e0e0e0e0e0e0e0000e6e7e8e9eaeb0000000000000000999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0c0e0e0e0e0e0e0e0e0e000000000000000000000000000000008d8d8d00000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0c0c0c0c0c0c0e0e0e0e0e0e0e0e0e00000000000000000000000000000000959500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0d0c0c0e0e0e0e0e0e0e0e0e00000000000000000000000000000000959500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00050000004200d4400c47000400054000640006400064001040010400104000f4000f400114000c4000c4000f400104000c5000c5000d5001050012500146001860000000000000000000000000000000000000
000300002657025550355403451034510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000335502f550255502552026510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
071100003862030620256203862030620256203862030620256200060019600196002a50000600186000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000004100d4200c43000400054000640006400064001040010400104000f4000f400114000c4000c4000f400104000c5000c5000d5001050012500146001860000000000000000000000000000000000000
1403000038420384203a4203c420354003840038420384203a4203c4200a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000014550065500e5501755010550195502155021550215500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700002650025500355003450034500265002550035500345003450026500255003550034500345000000026500265402552035510345103451026540255203551034510345102654025520355103451034510
010600001445016e50186501bc500ec501ff501c6501c6500c6300c6200c6100b6101e60020600206002060000000000000000000000000000000000000000000000000000000000000000000000000000000000
53060000164303b4301df00016001963018630186301861017e001963018630186301861000600006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c07000010c5027c5032c003770000000367000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900300001235001650006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070000046100462000600186003a6303a630366302c620216200e6200d6100e6100c6100d6100e6100d6100e6100c6100d6100e6100d6100e6000c6000d6000e6000d6000e6000c6000d600000000000000000
0703000010640326402d6202e9102f9102f9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8510000c11d550fd540bd550ad5409d5508d5407d5506d5405d5504d5403d5502d5401d5500d54000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000717b111bb111bb111bb1209b1207b1204b1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000023910259102a9102b9302b9302b940299202a910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002405022050240502705027050000002405022050240502705027050000002405022000220502405027050200502005000000000000000000000000000000000000000000000000000000000000000000
011000002765527655256550060000000246550000527655276552465500005000052465500605276552765524655000002765327653276530060000000276530000027653276532765300000000000000000000
0110000024132000002213222033180001f1321f033180001b132000001d1321d0330000018132180330000018030000001f0301d030000001b0321b034000001b0321b034000001b0331b033000001b03300000
050400000491207911029150591501913129550795512900009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000030f5128f2117a410cf4107f4106f410e4510e551000010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 06074344
00 12134344

