#include <stdio.h>
#include <stdlib.h>

#include <cuda.h>
#include <opencv2/opencv.hpp>

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
  /* add your custom pre-process here */
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
  /* add your custom post-process here */
}

static void cv_process(void *pdata, int32_t width, int32_t height)
{
//  cv::cuda::GpuMat d_mat(height, width, CV_8UC4, pdata);
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
	cv_process(eglFrame.frame.pPitch[0], eglFrame.width, eglFrame.height);
    } else {
	printf ("Invalid eglcolorformat for opencv\n");
	std::cout<<eglFrame.eglColorFormat << ", " <<CU_EGL_COLOR_FORMAT_RGBA<<std::endl;
    }
  }
  else {
     printf ("Invalid frame type for opencv\n");
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

extern "C" void
init (CustomerFunction * pFuncs)
{
  pFuncs->fPreProcess = pre_process;
  pFuncs->fGPUProcess = gpu_process;
  pFuncs->fPostProcess = post_process;
}
