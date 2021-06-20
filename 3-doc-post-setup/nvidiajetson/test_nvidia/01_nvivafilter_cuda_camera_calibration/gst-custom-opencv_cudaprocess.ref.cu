#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include <cuda.h>

#include "opencv2/core.hpp"
#include "opencv2/calib3d.hpp"
#include "opencv2/cudawarping.hpp" 

#include "cudaEGL.h"

#if defined(__cplusplus)
extern "C" void Handle_EGLImage (EGLImageKHR image);
extern "C" {
#endif

typedef enum {
  COLOR_FORMAT_Y8 = 0,
  COLOR_FORMAT_U8_V8,
  COLOR_FORMAT_RGBA,
  COLOR_FORMAT_NONE
} ColorFormat;

typedef struct {
  void (*fGPUProcess) (EGLImageKHR image, void ** userPtr);
  void (*fPreProcess)(void **sBaseAddr,
                      unsigned int *smemsize,
                      unsigned int *swidth,
                      unsigned int *sheight,
                      unsigned int *spitch,
                      ColorFormat *sformat,
                      unsigned int nsurfcount,
                      void ** userPtr);
  void (*fPostProcess)(void **sBaseAddr,
                      unsigned int *smemsize,
                      unsigned int *swidth,
                      unsigned int *sheight,
                      unsigned int *spitch,
                      ColorFormat *sformat,
                      unsigned int nsurfcount,
                      void ** userPtr);
} CustomerFunction;

void init (CustomerFunction * pFuncs);

#if defined(__cplusplus)
}
#endif


static void
pre_process (void **sBaseAddr,
                unsigned int *smemsize,
                unsigned int *swidth,
                unsigned int *sheight,
                unsigned int *spitch,
                ColorFormat  *sformat,
                unsigned int nsurfcount,
                void ** usrptr)
{
   printf ("pre-process %dx%d size %d\n", *swidth, *sheight, *smemsize); 
}

static void
post_process (void **sBaseAddr,
                unsigned int *smemsize,
                unsigned int *swidth,
                unsigned int *sheight,
                unsigned int *spitch,
                ColorFormat  *sformat,
                unsigned int nsurfcount,
                void ** usrptr)
{
   printf ("post-process %dx%d size %d\n", *swidth, *sheight, *smemsize); 
}



static cv::cuda::GpuMat gpu_xmap, gpu_ymap;

static void cv_process_RGBA(void *pdata, int32_t width, int32_t height)
{
    cv::cuda::GpuMat d_Mat_RGBA(height, width, CV_8UC4, pdata);
    cv::cuda::GpuMat d_Mat_RGBA_Src;
    d_Mat_RGBA.copyTo(d_Mat_RGBA_Src); // cannot avoid one copy
    cv::cuda::remap(d_Mat_RGBA_Src, d_Mat_RGBA, gpu_xmap, gpu_ymap, cv::INTER_CUBIC, cv::BORDER_CONSTANT, cv::Scalar(0.f, 0.f, 0.f, 0.f));

    // Check
    if(d_Mat_RGBA.data != pdata)
	std::cerr << "Error reallocated buffer for d_Mat_RGBA" << std::endl;
}

static void
gpu_process (EGLImageKHR image, void ** usrptr)
{
  CUresult status;
  CUeglFrame eglFrame;
  CUgraphicsResource pResource = NULL;

  cudaFree(0);
  status = cuGraphicsEGLRegisterImage(&pResource, image, CU_GRAPHICS_MAP_RESOURCE_FLAGS_NONE);

  if (status != CUDA_SUCCESS) {
    printf("cuGraphicsEGLRegisterImage failed : %d \n", status);
    return;
  }

  status = cuGraphicsResourceGetMappedEglFrame( &eglFrame, pResource, 0, 0);
  if (status != CUDA_SUCCESS) {
    printf ("cuGraphicsSubResourceGetMappedArray failed\n");
  }

  status = cuCtxSynchronize();
  if (status != CUDA_SUCCESS) {
    printf ("cuCtxSynchronize failed \n");
  }

  if (eglFrame.frameType == CU_EGL_FRAME_TYPE_PITCH) {
    if (eglFrame.eglColorFormat == CU_EGL_COLOR_FORMAT_ABGR) {
 	cv_process_RGBA(eglFrame.frame.pPitch[0], eglFrame.width, eglFrame.height);
    } else if (eglFrame.eglColorFormat == CU_EGL_COLOR_FORMAT_YUV420_SEMIPLANAR) {
      printf ("Invalid eglcolorformat NV12\n");
    } else
      printf ("Invalid eglcolorformat %d\n", eglFrame.eglColorFormat);
  }

  status = cuCtxSynchronize();
  if (status != CUDA_SUCCESS) {
    printf ("cuCtxSynchronize failed after memcpy \n");
  }

  status = cuGraphicsUnregisterResource(pResource);
  if (status != CUDA_SUCCESS) {
    printf("cuGraphicsEGLUnRegisterResource failed: %d \n", status);
  }
}

const int max_width = 640;
const int max_height = 480;

extern "C" void
init (CustomerFunction * pFuncs)
{
  pFuncs->fPreProcess = pre_process;
  pFuncs->fGPUProcess = gpu_process;
  pFuncs->fPostProcess = post_process;

  /* Initialize maps from CPU */
  cv::Mat xmap(max_height, max_width, CV_32FC1);
  cv::Mat ymap(max_height, max_width, CV_32FC1);

  //fill matrices
  cv::Mat cam(3, 3, cv::DataType<float>::type);
  cam.at<float>(0, 0) = 528.53618582196384f;
  cam.at<float>(0, 1) = 0.0f;
  cam.at<float>(0, 2) = 314.01736116032430f;

  cam.at<float>(1, 0) = 0.0f;
  cam.at<float>(1, 1) = 532.01912214324500f;
  cam.at<float>(1, 2) = 231.43930864205211f;

  cam.at<float>(2, 0) = 0.0f;
  cam.at<float>(2, 1) = 0.0f;
  cam.at<float>(2, 2) = 1.0f;

  cv::Mat dist(4, 1, cv::DataType<float>::type);  
  dist.at<float>(0, 0) = -0.11839989180635836f;
  dist.at<float>(1, 0) = 0.25425420873955445f;
  dist.at<float>(2, 0) = 0.0013269901775205413f;
  dist.at<float>(3, 0) = 0.0015787467748277866f;

  cv::fisheye::initUndistortRectifyMap(cam, dist, cv::Mat(), cam, cv::Size(max_width, max_height), CV_32FC1, xmap, ymap);

  /* upload to GpuMats */
  gpu_xmap.upload(xmap);
  gpu_ymap.upload(ymap);
}

extern "C" void
deinit (void)
{

}
