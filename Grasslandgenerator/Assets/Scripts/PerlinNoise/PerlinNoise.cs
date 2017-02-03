using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

/**
 * This Class implements Perlin Noise with the Help of Compute Shaders.
 * The function used to calculate the PerlinNoise is taken from 
 * https://forum.unity3d.com/threads/2d-3d-4d-optimised-perlin-noise-cg-hlsl-library-cginc.218372/
 * 
 * Usage:
 * 
 * create new PerlinNoise Object and provide the ComputeShader
 * PerlinNoise p = new PerlinNoise(refToComputeSHader);
 * 
 * call the noise function with desired array of Vectors
 * p.noise(Vector2[] v2);
 * p.noise(Vector3[] v3);
 * p.noise(Vector4[] v4);
 * 
 * Result is a float[] with the respective noisevalues
 */
public class PerlinNoise {

    // Threads per ThreadGroup in the ComputeShader
    private const int threadsPerGroup = 256;

    // ComputeShader Declaration
    ComputeShader _computeShader;

    // Input and OutputBuffer to/from ComputeShader
    ComputeBuffer _outputBuffer;
    ComputeBuffer _inputBuffer;

    // DataFrom OutPutBuffer
    computeOutput[] _computeOutput;

    // OutputStruct from ComputeShader
    public struct computeOutput
    {
        public float noise;
    }

    // Creates a new PerlinNoise Instance
    public PerlinNoise(ComputeShader computeShader)
    {
        _computeShader = computeShader;
    }

    // Calculates the noisevalues for a Vector2[]
    public float[] noise(Vector2[] input)
    {
        // Get the Kernel for 2D PerlinNoise
        int csKernel = _computeShader.FindKernel("CSMain2D");

        // Sets up the Buffers, Dispatches the Threads and saves the output
        DispatchComputeShader(csKernel, input.Length, 2, input);

        // Releases all Buffers after execution
        releaseBuffers();

        // Extracts the Data from the Output and returns it
        return extractDataFromOutput(_computeOutput);
    }

    // Calculates the noisevalues for a Vector3[]
    public float[] noise(Vector3[] input)
    {
        // Get the Kernel for 3D PerlinNoise
        int csKernel = _computeShader.FindKernel("CSMain3D");

        // Sets up the Buffers, Dispatches the Threads and saves the output
        DispatchComputeShader(csKernel, input.Length, 3, input);

        // Releases all Buffers after execution
        releaseBuffers();

        // Extracts the Data from the Output and returns it
        return extractDataFromOutput(_computeOutput);
    }

    // Calculates the noisevalues for a Vector4[]
    public float[] noise(Vector4[] input)
    {
        // Get the Kernel for 4D PerlinNoise
        int csKernel = _computeShader.FindKernel("CSMain4D");

        // Sets up the Buffers, Dispatches the Threads and saves the output
        DispatchComputeShader(csKernel, input.Length, 4, input);

        // Releases all Buffers after execution
        releaseBuffers();

        // Extracts the Data from the Output and returns it
        return extractDataFromOutput(_computeOutput);
    }

    // Sets Buffers, data and dispatches the Threads
    // Afterwards reads the output and saves it
    private void DispatchComputeShader(int csKernel, int inputLength, int dimension, Array input)
    {
        // Initialize Buffers with correct Sizes
        _outputBuffer = new ComputeBuffer(inputLength, 4);
        _inputBuffer = new ComputeBuffer(inputLength, 4 * dimension);
        _inputBuffer.SetData(input);

        // Set the Buffers on the ComputeShader
        _computeShader.SetBuffer(csKernel, "_outputBuffer", _outputBuffer);
        _computeShader.SetBuffer(csKernel, "_inputBuffer" + dimension + "D", _inputBuffer);
        _computeShader.SetInt("_numPoints", inputLength);

        // Calculate ThradGroupSize
        int threadGroupSize = (int)Math.Ceiling(((double)inputLength / (double)threadsPerGroup));

        // Dispatch all Threads
        _computeShader.Dispatch(csKernel, threadGroupSize, 1, 1);

        // Read the Data from outputBuffer
        _computeOutput = new computeOutput[inputLength];
        _outputBuffer.GetData(_computeOutput);
    }

    private void releaseBuffers()
    {
        if(_outputBuffer != null)
        {
            _outputBuffer.Release();
        }
        if(_inputBuffer != null)
        {
            _inputBuffer.Release();
        }
    }
    
    // Extracts the Data from the saved output to an float[]
    private float[] extractDataFromOutput(computeOutput[] computeOutput)
    {
        float[] output = new float[computeOutput.Length];
        for (int i = 0; i < computeOutput.Length; i++)
        {
            output[i] = computeOutput[i].noise;
        }

        return output;
    }
}
