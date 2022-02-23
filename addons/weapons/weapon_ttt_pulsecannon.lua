 AddCSLuaFile()

 -- Code provided by sparky for primary fire and reused to create a modified secondary fire
 -- I want to rewrite the secondary fire for its original use if I have time
 -- File Written by Akechi 28/02/2018

if CLIENT then
   SWEP.PrintName = "Pulse Cannon"
   SWEP.Slot = 7
   SWEP.Icon = "vgui/ttt/icon_rpg"
   SWEP.IconLetter = "P"

   SWEP.EquipMenuData = {
        type = "item_weapon",
        desc =
[[Will emit a small pulse that sends you flying!
Left Click: Small weak shot with a low delay
between shots
Right Click: Powerful shot with a 10 second
cooldown]]
    }

end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "ar2"

SWEP.Primary.Delay = 1
SWEP.Primary.Sound = Sound( "ambient/machines/catapult_throw.wav")
SWEP.Primary.Range = 170 -- Set to somehwere between 125 and 175, lower makes it harder to land safe
SWEP.Primary.Force = 600 -- Recommend you don't really touch this

SWEP.Secondary.Delay = 10
SWEP.Secondary.Sound = Sound( "weapons/airboat/airboat_gun_energy2.wav")
SWEP.Secondary.Range = 250
SWEP.Secondary.Force = 900

SWEP.CanBuy        = {ROLE_TRAITOR, ROLE_DETECTIVE}

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 60
SWEP.ViewModel = Model( "models/weapons/v_rpg.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_rocket_launcher.mdl" )

SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.InLoadoutFor = {}
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true

if CLIENT then
  local sights_opacity = CreateConVar("ttt_ironsights_crosshair_opacity", "0.8", FCVAR_ARCHIVE)
  local crosshair_brightness = CreateConVar("ttt_crosshair_brightness", "1.0", FCVAR_ARCHIVE)
  local crosshair_size = CreateConVar("ttt_crosshair_size", "1.0", FCVAR_ARCHIVE)
  local disable_crosshair = CreateConVar("ttt_disable_crosshair", "0", FCVAR_ARCHIVE)


  function SWEP:DrawHUD()
    if self.HUDHelp then
      self:DrawHelp()
    end

    local client = LocalPlayer()
    if disable_crosshair:GetBool() or (not IsValid(client)) then return end

    local sights = (not self.NoSights) and self:GetIronsights()

    local x = math.floor(ScrW() / 2.0)
    local y = math.floor(ScrH() / 2.0)
    local scale = math.max(0.2,  10 * self:GetPrimaryCone())

    local LastShootTime = self:LastShootTime()
    scale = scale * (2 - math.Clamp( (CurTime() - LastShootTime) * 5, 0.0, 1.0 ))

    local alpha = sights and sights_opacity:GetFloat() or 1
    local bright = crosshair_brightness:GetFloat() or 1

      -- somehow it seems this can be called before my player metatable
      -- additions have loaded
    if client.IsTraitor and client:IsTraitor() then
        surface.SetDrawColor(255 * bright,
                      50 * bright,
                      50 * bright,
                      255 * alpha)
    else
        surface.SetDrawColor(0,
                      255 * bright,
                      0,
                      255 * alpha)
    end

    local gap = math.floor(20 * scale * (sights and 0.8 or 1))
    local length = math.floor(gap + (25 * crosshair_size:GetFloat()) * scale)
    surface.DrawLine( x - length, y, x - gap, y )
    surface.DrawLine( x + length, y, x + gap, y )
    surface.DrawLine( x, y - length, x, y - gap )
    surface.DrawLine( x, y + length, x, y + gap )

    local padY = ScrH() / 64
    local offsetY = ScrH() / 32
    local w, h = ScrW() / 16, ScrH() / 48

    local midX, midY = ScrW() / 2, ScrH() / 2

    if self:GetNextPrimaryFire() > CurTime() then
        local filledAmount = (self:GetNextPrimaryFire() - CurTime()) / self.Primary.Delay

        surface.DrawRect(midX - w / 2, midY - h / 2 + offsetY, w * filledAmount, h)
        surface.DrawOutlinedRect(midX - w / 2, midY - h / 2 + offsetY, w, h)

        surface.SetTextColor(Color(255, 255, 255))
        surface.SetFont("Default")
        local texW, texH = surface.GetTextSize("Primary")
        surface.SetTextPos(midX - texW / 2, midY + offsetY - texH / 2)
        surface.DrawText("Primary")
    end

    if self:GetNextSecondaryFire() > CurTime() then
        local filledAmount = (self:GetNextSecondaryFire() - CurTime()) / self.Secondary.Delay

        surface.DrawRect(midX - w / 2, midY - h / 2 + h + padY + offsetY, w * filledAmount, h)
        surface.DrawOutlinedRect(midX - w / 2, midY - h / 2 + h + padY + offsetY, w, h)

        surface.SetTextColor(Color(255, 255, 255))
        surface.SetFont("Default")
        local texW, texH = surface.GetTextSize("Secondary")
        surface.SetTextPos(midX - texW / 2, midY + h + padY + offsetY - texH / 2)
        surface.DrawText("Secondary")
    end

  end
end


function SWEP:PreDrop()
   return self.BaseClass.PreDrop( self )
end

function SWEP:Holster()
   return true
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

    if CurTime() + self.Primary.Delay > self:GetNextSecondaryFire() then
        self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
    end

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    if SERVER then self:GetOwner():LagCompensation(true) end

    local tr = util.TraceLine({
        start = self:GetOwner():EyePos(),
        endpos = self:GetOwner():EyePos() + (self:GetOwner():GetAimVector() * self.Primary.Range),
        filter = {self:GetOwner(), self},
        mask = MASK_SOLID
    })

    if SERVER then self:GetOwner():LagCompensation(false) end

    local validShot = tr.Entity:IsValid() or tr.Entity:IsWorld()

    if SERVER and validShot then
        self:GetOwner():SetVelocity(self:GetOwner():GetVelocity() / 8, 0)
        self:GetOwner():SetVelocity(-self:GetOwner():GetAimVector() * self.Primary.Force, 0)
    end

    if IsFirstTimePredicted() then
        if not worldsnd then
            self:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )
        elseif SERVER then
            sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
        end

        if tr.Entity and tr.Entity:IsWorld() then
            util.Decal("FadingScorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)

            local effectData = EffectData()
            effectData:SetOrigin(tr.HitPos)
            effectData:SetNormal(tr.HitNormal)
            util.Effect("cball_explode", effectData)
        end
    end

    self:GetOwner():ViewPunch( Angle( -self.Primary.Recoil, 0, 0 ) )
end

function SWEP:SecondaryAttack()
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    if SERVER then self:GetOwner():LagCompensation(true) end

    local tr = util.TraceLine({
        start = self:GetOwner():EyePos(),
        endpos = self:GetOwner():EyePos() + (self:GetOwner():GetAimVector() * self.Secondary.Range),
        filter = {self:GetOwner(), self},
        mask = MASK_SOLID
    })

    if SERVER then self:GetOwner():LagCompensation(false) end
    
    local validShot = tr.Entity:IsValid() or tr.Entity:IsWorld()

    if SERVER and validShot then
        self:GetOwner():SetVelocity(self:GetOwner():GetVelocity() / 8, 0)
        self:GetOwner():SetVelocity(-self:GetOwner():GetAimVector() * self.Secondary.Force, 0)
    end

    if IsFirstTimePredicted() then
        if not worldsnd then
        self:EmitSound( self.Secondary.Sound, self.Secondary.SoundLevel )
        elseif SERVER then
        sound.Play(self.Secondary.Sound, self:GetPos(), self.Secondary.SoundLevel)
        end

        if tr.Entity and tr.Entity:IsWorld() then
            util.Decal("FadingScorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)

            local effectData = EffectData()
            effectData:SetOrigin(tr.HitPos)
            effectData:SetNormal(tr.HitNormal)
            util.Effect("cball_explode", effectData)
        end
    end

    self:GetOwner():ViewPunch( Angle( -self.Primary.Recoil, 0, 0 ) )
end
