local path = (...):sub(1, -string.len(".core.puppet") - 1)

local Object = require(path..".lib.classic")

---@class Inochi2D.Puppet
local Puppet = Object:extend()

-- Magic value meaning that the model has no thumbnail
Puppet.NO_THUMBNAIL = 4294967295;

---@alias Inochi2D.PuppetAllowedUsers
---Only the author(s) are allowed to use the puppet
---| "onlyAuthor"
---Only licensee(s) are allowed to use the puppet
---| "onlyLicensee"
---Everyone may use the model
---| "everyone"

---@alias Inochi2D.PuppetAllowedRedistribution
---Redistribution is prohibited
---| "prohibited"
---Redistribution is allowed, but only under the same license as the original.
---| "viralLicense"
---Redistribution is allowed, and the puppet may be redistributed under a different license than the original.
---
---This goes in conjunction with modification rights.
---| "copyleftLicense"

---@alias Inochi2D.PuppetAllowedModification
---Modification is prohibited
---| "prohibited"
---Modification is only allowed for personal use
---| "allowPersonal"
---Modification is allowed with redistribution, see `allowedRedistribution` for redistribution terms.
---| "allowRedistribute"

---@class Inochi2D.PuppetUsageRights
---@field public allowedUsers Inochi2D.PuppetAllowedUsers Who is allowed to use the puppet?
---@field public allowViolence boolean Whether violence content is allowed
---@field public allowSexual boolean Whether sexual content is allowed
---@field public allowCommercial boolean Whether commerical use is allowed
---@field public allowRedistribution Inochi2D.PuppetAllowedRedistribution Whether a model may be redistributed
---@field public allowModification Inochi2D.PuppetAllowedModification Whether a model may be modified
---@field public requireAttribution boolean Whether the author(s) must be attributed for use.
Puppet.UsageRights = Object:extend()

---Puppet meta information
---@class Inochi2D.PuppetMeta
---@field public name string
---@field public version string
---@field public rigger string?
---@field public artist string?
---@field public rights Inochi2D.PuppetUsageRights?
---@field public copyright string?
---@field public license string?
---@field public contact string?
---@field public reference string?
---@field public thumbnailId integer
---@field public preservePixels boolean
Puppet.Meta = Object:extend()
