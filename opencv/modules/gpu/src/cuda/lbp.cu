/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or bpied warranties, including, but not limited to, the bpied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#include <opencv2/gpu/device/lbp.hpp>
#include <opencv2/gpu/device/vec_traits.hpp>
#include <opencv2/gpu/device/saturate_cast.hpp>

namespace cv { namespace gpu { namespace device
{
    namespace lbp
    {

        texture<int, cudaTextureType2D, cudaReadModeElementType> tintegral(false, cudaFilterModePoint, cudaAddressModeClamp);

        struct LBP
        {
            __host__ __device__ __forceinline__ LBP() {}

            // for integral matrix stored in the global memory
            __device__ __forceinline__ int operator() (const int* integral, int ty, int fh, int fw, int& shift) const
            {
                int anchors[9];

                anchors[0]  = integral[ty];
                anchors[1]  = integral[ty + fw];
                anchors[0] -= anchors[1];
                anchors[2]  = integral[ty + fw * 2];
                anchors[1] -= anchors[2];
                anchors[2] -= integral[ty + fw * 3];

                ty += fh;
                anchors[3]  = integral[ty];
                anchors[4]  = integral[ty + fw];
                anchors[3] -= anchors[4];
                anchors[5]  = integral[ty + fw * 2];
                anchors[4] -= anchors[5];
                anchors[5] -= integral[ty + fw * 3];

                anchors[0] -= anchors[3];
                anchors[1] -= anchors[4];
                anchors[2] -= anchors[5];
                // 0 - 2 contains s0 - s2

                ty += fh;
                anchors[6]  = integral[ty];
                anchors[7]  = integral[ty + fw];
                anchors[6] -= anchors[7];
                anchors[8]  = integral[ty + fw * 2];
                anchors[7] -= anchors[8];
                anchors[8] -= integral[ty + fw * 3];

                anchors[3] -= anchors[6];
                anchors[4] -= anchors[7];
                anchors[5] -= anchors[8];
                // 3 - 5 contains s3 - s5

                anchors[0] -= anchors[4];
                anchors[1] -= anchors[4];
                anchors[2] -= anchors[4];
                anchors[3] -= anchors[4];
                anchors[5] -= anchors[4];

                int response = (~(anchors[0] >> 31)) & 4;
                response |= (~(anchors[1] >> 31)) & 2;;
                response |= (~(anchors[2] >> 31)) & 1;

                shift = (~(anchors[5] >> 31)) & 16;
                shift |= (~(anchors[3] >> 31)) & 1;

                ty += fh;
                anchors[0]  = integral[ty];
                anchors[1]  = integral[ty + fw];
                anchors[0] -= anchors[1];
                anchors[2]  = integral[ty + fw * 2];
                anchors[1] -= anchors[2];
                anchors[2] -= integral[ty + fw * 3];

                anchors[6] -= anchors[0];
                anchors[7] -= anchors[1];
                anchors[8] -= anchors[2];
                // 0 -2 contains s6 - s8

                anchors[6] -= anchors[4];
                anchors[7] -= anchors[4];
                anchors[8] -= anchors[4];

                shift |= (~(anchors[6] >> 31)) & 2;
                shift |= (~(anchors[7] >> 31)) & 4;
                shift |= (~(anchors[8] >> 31)) & 8;
                return response;
            }
            // for texture fetchrd integral matrix
            __device__ __forceinline__ int operator() (int ty, int tx, int fh, int fw, int& shift) const
            {
                int anchors[9];

                anchors[0]  = tex2D(tintegral, tx, ty);
                anchors[1]  = tex2D(tintegral, tx + fw, ty);
                anchors[0] -= anchors[1];
                anchors[2]  = tex2D(tintegral, tx + fw * 2, ty);
                anchors[1] -= anchors[2];
                anchors[2] -= tex2D(tintegral, tx + fw * 3, ty);

                ty += fh;
                anchors[3]  = tex2D(tintegral, tx, ty);
                anchors[4]  = tex2D(tintegral, tx + fw, ty);
                anchors[3] -= anchors[4];
                anchors[5]  = tex2D(tintegral, tx + fw * 2, ty);
                anchors[4] -= anchors[5];
                anchors[5] -= tex2D(tintegral, tx + fw * 3, ty);

                anchors[0] -= anchors[3];
                anchors[1] -= anchors[4];
                anchors[2] -= anchors[5];
                // 0 - 2 contains s0 - s2

                ty += fh;
                anchors[6]  = tex2D(tintegral, tx, ty);
                anchors[7]  = tex2D(tintegral, tx + fw, ty);
                anchors[6] -= anchors[7];
                anchors[8]  = tex2D(tintegral, tx + fw * 2, ty);
                anchors[7] -= anchors[8];
                anchors[8] -= tex2D(tintegral, tx + fw * 3, ty);

                anchors[3] -= anchors[6];
                anchors[4] -= anchors[7];
                anchors[5] -= anchors[8];
                // 3 - 5 contains s3 - s5

                anchors[0] -= anchors[4];
                anchors[1] -= anchors[4];
                anchors[2] -= anchors[4];
                anchors[3] -= anchors[4];
                anchors[5] -= anchors[4];

                int response = (~(anchors[0] >> 31)) & 4;
                response |= (~(anchors[1] >> 31)) & 2;;
                response |= (~(anchors[2] >> 31)) & 1;

                shift = (~(anchors[5] >> 31)) & 16;
                shift |= (~(anchors[3] >> 31)) & 1;

                ty += fh;
                anchors[0]  = tex2D(tintegral, tx, ty);
                anchors[1]  = tex2D(tintegral, tx + fw, ty);
                anchors[0] -= anchors[1];
                anchors[2]  = tex2D(tintegral, tx + fw * 2, ty);
                anchors[1] -= anchors[2];
                anchors[2] -= tex2D(tintegral, tx + fw * 3, ty);

                anchors[6] -= anchors[0];
                anchors[7] -= anchors[1];
                anchors[8] -= anchors[2];
                // 0 -2 contains s6 - s8

                anchors[6] -= anchors[4];
                anchors[7] -= anchors[4];
                anchors[8] -= anchors[4];

                shift |= (~(anchors[6] >> 31)) & 2;
                shift |= (~(anchors[7] >> 31)) & 4;
                shift |= (~(anchors[8] >> 31)) & 8;
                return response;
            }
        };

        void bindIntegral(DevMem2Di integral)
        {
            cudaChannelFormatDesc desc = cudaCreateChannelDesc<int>();
            cudaSafeCall( cudaBindTexture2D(0, &tintegral, integral.ptr(), &desc, (size_t)integral.cols, (size_t)integral.rows, (size_t)integral.step));
        }

        void unbindIntegral()
        {
             cudaSafeCall( cudaUnbindTexture(&tintegral));
        }

        struct Classifier
        {
            __host__ __device__ __forceinline__ Classifier(const int* _integral, int _pitch, const Stage* _stages, const ClNode* _nodes, const float* _leaves,
                const int* _subsets, const uchar4* _features, int _nstages, int _clWidth, int _clHeight, float _scale, int _step, int _subsetSize)
            : integral(_integral), pitch(_pitch), stages(_stages), nodes(_nodes), leaves(_leaves), subsets(_subsets), features(_features), nstages(_nstages),
              clWidth(_clWidth), clHeight(_clHeight), scale(_scale), step(_step), subsetSize(_subsetSize){}

            __device__ __forceinline__ void operator() (int y, int x, DevMem2D_<int4> objects, const unsigned int maxN, unsigned int* n) const
            {
                int current_node = 0;
                int current_leave = 0;

                for (int s = 0; s < nstages; ++s)
                {
                    float sum = 0;
                    Stage stage = stages[s];
                    for (int t = 0; t < stage.ntrees; t++)
                    {
                        ClNode node = nodes[current_node];
                        uchar4 feature = features[node.featureIdx];

                        int shift;
                        // int c = evaluator(y + feature.y, x + feature.x, feature.w, feature.z, shift);
                        int c = evaluator(integral, (y + feature.y) * pitch + x + feature.x, feature.w * pitch, feature.z, shift);
                        int idx =  (subsets[ current_node * subsetSize + c] & ( 1 << shift)) ? current_leave : current_leave + 1;
                        sum += leaves[idx];

                        current_node += 1;
                        current_leave += 2;
                    }

                    if (sum < stage.threshold)
                        return;
                }

                int4 rect;
                rect.x = roundf(x * scale);
                rect.y = roundf(y * scale);
                rect.z = clWidth;
                rect.w = clHeight;

                int res = Emulation::smem::atomicInc(n, maxN);
                objects(0, res) = rect;
            }

            const int* integral;
            const int pitch;

            const Stage*  stages;
            const ClNode* nodes;
            const float* leaves;
            const int* subsets;
            const uchar4* features;

            const int nstages;
            const int clWidth;
            const int clHeight;
            const float scale;
            const int step;
            const int subsetSize;
            const LBP evaluator;
        };

        __global__ void lbp_classify_stump(const Classifier classifier, DevMem2D_<int4> objects, const unsigned int maxN, unsigned int* n)
        {
            int x = threadIdx.x * classifier.step;
            int y = blockIdx.x * classifier.step;

            classifier(y, x, objects, maxN, n);
        }

        __global__ void lbp_classify_stump(const Classifier classifier, DevMem2D_<int4> objects, const unsigned int maxN, unsigned int* n, int maxX)
        {
            int ftid = blockIdx.x * blockDim.x + threadIdx.x;
            int y = ftid / maxX;
            int x = ftid - y * maxX;

            classifier(y * classifier.step, x * classifier.step, objects, maxN, n);
        }

        template<typename Pr>
        __global__ void disjoin(int4* candidates, int4* objects, unsigned int n, int groupThreshold, float grouping_eps, unsigned int* nclasses)
        {
            unsigned int tid = threadIdx.x;
            extern __shared__ int sbuff[];

            int* labels = sbuff;
            int* rrects = sbuff + n;

            Pr predicate(grouping_eps);
            partition(candidates, n, labels, predicate);

            rrects[tid * 4 + 0] = 0;
            rrects[tid * 4 + 1] = 0;
            rrects[tid * 4 + 2] = 0;
            rrects[tid * 4 + 3] = 0;
            __syncthreads();

            int cls = labels[tid];
            Emulation::smem::atomicAdd((rrects + cls * 4 + 0), candidates[tid].x);
            Emulation::smem::atomicAdd((rrects + cls * 4 + 1), candidates[tid].y);
            Emulation::smem::atomicAdd((rrects + cls * 4 + 2), candidates[tid].z);
            Emulation::smem::atomicAdd((rrects + cls * 4 + 3), candidates[tid].w);

            __syncthreads();
            labels[tid] = 0;

            __syncthreads();
            Emulation::smem::atomicInc((unsigned int*)labels + cls, n);

            __syncthreads();
            *nclasses = 0;

            int active = labels[tid];
            if (active)
            {
                int* r1 = rrects + tid * 4;
                float s = 1.f / active;
                r1[0] = saturate_cast<int>(r1[0] * s);
                r1[1] = saturate_cast<int>(r1[1] * s);
                r1[2] = saturate_cast<int>(r1[2] * s);
                r1[3] = saturate_cast<int>(r1[3] * s);
            }
            __syncthreads();

            if (active && active >= groupThreshold)
            {
                int* r1 = rrects + tid * 4;
                int4 r_out = make_int4(r1[0], r1[1], r1[2], r1[3]);

                int aidx = Emulation::smem::atomicInc(nclasses, n);
                objects[aidx] = r_out;
            }
        }

        void classifyStumpFixed(const DevMem2Di& integral, const int pitch, const DevMem2Db& mstages, const int nstages, const DevMem2Di& mnodes, const DevMem2Df& mleaves, const DevMem2Di& msubsets, const DevMem2Db& mfeatures,
                           const int workWidth, const int workHeight, const int clWidth, const int clHeight, float scale, int step, int subsetSize, DevMem2D_<int4> objects, unsigned int* classified)
        {
            Classifier clr(integral, pitch, (Stage*)mstages.ptr(), (ClNode*)mnodes.ptr(), mleaves.ptr(), msubsets,
                (uchar4*)mfeatures.ptr(), nstages, clWidth, clHeight, scale, step, subsetSize);

            int total = ceilf(workHeight / (float)step) * ceilf(workWidth / (float)step);

            int block = 256;
            int grid  = divUp(total, block);
            lbp_classify_stump<<<grid, block>>>(clr, objects, objects.cols, classified, workWidth >> 1);
            cudaSafeCall( cudaGetLastError() );
        }

        void connectedConmonents(DevMem2D_<int4> candidates, int ncandidates, DevMem2D_<int4> objects, int groupThreshold, float grouping_eps, unsigned int* nclasses)
        {
            int block = ncandidates;
            int smem  = block * ( sizeof(int) + sizeof(int4) );
            disjoin<InSameComponint><<<1, block, smem>>>(candidates, objects, ncandidates, groupThreshold, grouping_eps, nclasses);
            cudaSafeCall( cudaGetLastError() );
        }

        struct Cascade
        {
            __host__ __device__ __forceinline__ Cascade(const Stage* _stages, int _nstages, const ClNode* _nodes, const float* _leaves,
                const int* _subsets, const uchar4* _features, int _subsetSize)

            : stages(_stages), nstages(_nstages), nodes(_nodes), leaves(_leaves), subsets(_subsets), features(_features), subsetSize(_subsetSize){}

            __device__ __forceinline__ bool operator() (int y, int x, int* integral, const int pitch/*, DevMem2D_<int4> objects, const unsigned int maxN, unsigned int* n*/) const
            {
                int current_node = 0;
                int current_leave = 0;

                for (int s = 0; s < nstages; ++s)
                {
                    float sum = 0;
                    Stage stage = stages[s];
                    for (int t = 0; t < stage.ntrees; t++)
                    {
                        ClNode node = nodes[current_node];
                        uchar4 feature = features[node.featureIdx];

                        int shift;
                        int c = evaluator(integral, (y + feature.y) * pitch + x + feature.x, feature.w * pitch, feature.z, shift);
                        int idx =  (subsets[ current_node * subsetSize + c] & ( 1 << shift)) ? current_leave : current_leave + 1;
                        sum += leaves[idx];

                        current_node += 1;
                        current_leave += 2;
                    }

                    if (sum < stage.threshold)
                        return false;
                }

                return true;
            }

            const Stage*  stages;
            const int nstages;

            const ClNode* nodes;
            const float* leaves;
            const int* subsets;
            const uchar4* features;

            const int subsetSize;
            const LBP evaluator;
        };

        // stepShift, scale, width_k, sum_prev => y =  sum_prev + tid_k / width_k, x = tid_k - tid_k / width_k
        __global__ void lbp_cascade(const Cascade cascade, int frameW, int frameH, int windowW, int windowH, float scale, const float factor,
            const int workAmount, int* integral, const int pitch, DevMem2D_<int4> objects, unsigned int* classified)
        {
            int ftid = blockIdx.x * blockDim.x + threadIdx.x;
            if (ftid >= workAmount ) return;

            int sum = 0;
            // float scale = 1.0f;
            float stepShift = (scale <= 2.f) ? 2.0 : 1.0;
            int w = ceilf( ( __float2int_rn(frameW / scale) - windowW + 1) / stepShift);
            int h = ceilf( ( __float2int_rn(frameH / scale) - windowH + 1) / stepShift);

            // if (!ftid)
                // printf("!!!!: %d %d", w, h);

            int framTid = ftid;
            int i = 0;

            while (1)
            {
                if (framTid < (w - 1) * (h - 1)) break;
                i++;
                sum +=  __float2int_rn(frameW / scale) + 1;
                framTid -= w * h;
                scale *= factor;
                stepShift = (scale <= 2.f) ? 2.0 : 1.0;
                int w = ceilf( ( __float2int_rn(frameW / scale) - windowW + 1) / stepShift);
                int h = ceilf( ( __float2int_rn(frameH / scale) - windowH + 1) / stepShift);
            }

            int y = (framTid / w);
            int x = (framTid - y * w) * stepShift;
            y *= stepShift;
            x += sum;

            // if (i == 2)
            // printf("!!!!!!!!!!!!!! %f %d %d %d\n", windowW * scale, sum, y, x);

            if (cascade(y, x, integral, pitch))
            {
                int4 rect;
                rect.x = roundf( (x - sum) * scale);
                rect.y = roundf(y * scale);
                rect.z = roundf(windowW * scale);
                rect.w = roundf(windowH * scale);

                if (rect.x > frameW || rect.y > frameH) return;
                    // printf("OUTLAUER %d %d %d %d %d %d %d %d %d %f %f\n", x, y, ftid, framTid, rect.x, rect.y, sum, w, h, stepShift, scale);

                // printf("passed: %d %d ---- %d %d %d %d %d\n", y, x, rect.x, rect.y, rect.z, rect.w, sum);

                int res = Emulation::smem::atomicInc(classified, (unsigned int)objects.cols);
                objects(0, res) = rect;

            }
        }

        void classifyPyramid(int frameW, int frameH, int windowW, int windowH, float initialScale, float factor, int workAmount,
            const DevMem2Db& mstages, const int nstages, const DevMem2Di& mnodes, const DevMem2Df& mleaves, const DevMem2Di& msubsets, const DevMem2Db& mfeatures,
            const int subsetSize, DevMem2D_<int4> objects, unsigned int* classified, DevMem2Di integral)
        {
            const int block = 256;
            int grid = divUp(workAmount, block);
            Cascade cascade((Stage*)mstages.ptr(), nstages, (ClNode*)mnodes.ptr(), mleaves.ptr(), msubsets.ptr(), (uchar4*)mfeatures.ptr(), subsetSize);
            lbp_cascade<<<grid, block>>>(cascade, frameW, frameH, windowW, windowH, initialScale, factor, workAmount, integral.ptr(), integral.step / sizeof(int), objects, classified);
        }
    }
}}}