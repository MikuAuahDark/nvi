---@class NVi.Metadata
---@field public title string
---@field public artist string
---@field public album string
---@field public coverArt love.Image
local Metadata = {}

---@class NVi.BaseVisualizer
local BaseVisualizer = {}

---@param args table<string, any>
---@param metadata NVi.Metadata
---@return {samples: number, fft: boolean, band: {count: number, overlap: boolean, windowing: nil|'"hann"'|'"hamming"'}, sensitivity: number}
function BaseVisualizer.load(args, metadata)
end

---@param dt number
---@param samples number[][] @[channel][sampleindex]
---@param fft number[]
---@param bands number[]
function BaseVisualizer.update(dt, samples, fft, bands)
end

function BaseVisualizer.draw()
end
