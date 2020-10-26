
using QML, JSON, BSON, Printf, Parameters, Distributed
using Images, ImageFiltering, ImageTransformations, ImageMorphology, DSP
using Flux,Flux.Losses, Random, CUDAapi, Statistics, Plots
import Base.string, Base.any, Base.copy!, ImageSegmentation.label_components
import CUDA, Base.kill
CUDA.allowscalar(true)
