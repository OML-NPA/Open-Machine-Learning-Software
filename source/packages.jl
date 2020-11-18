
using QML, JSON, BSON, Printf, Parameters, Dates, FileIO
using Images, ImageFiltering, ImageTransformations, ImageMorphology, DSP
using Flux, Flux.Losses, Random, CUDAapi, Statistics, Plots
using ImageSegmentation, Combinatorics, Distances, ImageMorphology.FeatureTransform
import Base.string, Base.any, Base.copy!, ImageSegmentation.label_components
import CUDA, CUDA.CuArray, Flux.outdims
CUDA.allowscalar(false)
gc() = GC.gc()
