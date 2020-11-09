
using QML, JSON, BSON, Printf, Parameters, Distributed, Dates, FileIO
using Images, ImageFiltering, ImageTransformations, ImageMorphology, DSP
using Flux, Flux.Losses, Random, CUDAapi, Statistics, Plots
using ImageSegmentation, Combinatorics
import Base.string, Base.any, Base.copy!, ImageSegmentation.label_components
import CUDA, CUDA.CuArray, Flux.outdims
CUDA_fill = CUDA.fill
CUDA.allowscalar(false)
