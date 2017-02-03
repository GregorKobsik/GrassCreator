using UnityEngine;
using System.Collections;

public class RainCreator : MonoBehaviour
{

    #region Rain Compute Shader

    // Should equal MESH_SIZE
    public int RainSize = 128;
    int DropsPerUnit = 5;

    // Sets the Height where the Rain starts
    public int RainHeight = 64;

    // Sets the Position where the Rain should be
    public Vector3 RainPosition = new Vector3(0.0f, 0.0f, 0.0f);

    // Rain Speed
    [Range(1, 200)]
    public float Speed = 100;

    // Distance between Rain Drops
    [Range(0.1f, 1.0f)]
    public float Density = 0.3f;

    // Starting y Offsets
    float[] startOffsets;

    // Random Velocities per Drop
    Vector2[] dropVelocities;

    public ComputeShader ComputeShader;
    const int THREADS_PER_GROUP = 64;
    const int THREAD_GROUP_X_SIZE = 16;
    const int THREAD_GROUP_Y_SIZE = 16;
    const int THREAD_GROUP_Z_SIZE = 1;

    // 32 * 32 * 16 * 16 Rain Drops
    int RAIN_DROPS_COUNT_CURRENT;

    // Used to not calculate all Positions in every frame
    // instead we only calculate if the value changes
    int RAIN_DROPS_COUNT_PREVIOUS;

    // Buffer to store start positions for each drop
    ComputeBuffer startPointBuffer;

    public struct positionStruct
    {
        public Vector3 pos;
    }

    bool isRunning;

    // output buffer for the computed data
    public ComputeBuffer outputBuffer1;
    public ComputeBuffer outputBuffer2;
    public positionStruct[] positions;
    
    // Buffer to pass the FrameTime to the Shader
    ComputeBuffer frameTimeBuffer;

    // Buffer to pass the Velocities to the Shader
    ComputeBuffer velocitiesBuffer;

    int CSKernel;

    #endregion

    void Start()
    {
        isRunning = true;
        // Calculate the Amount of RainDrops
        RAIN_DROPS_COUNT_CURRENT = (int)Mathf.Ceil(RainSize * DropsPerUnit * RainSize * DropsPerUnit * Density);
        RAIN_DROPS_COUNT_PREVIOUS = RAIN_DROPS_COUNT_CURRENT;
        generateStartAndVelocityValues();

        InitializeBuffers();
    }

    private void OnEnable()
    {
        isRunning = true;
        // Calculate the Amount of RainDrops
        RAIN_DROPS_COUNT_CURRENT = (int)Mathf.Ceil(RainSize * DropsPerUnit * RainSize * DropsPerUnit * Density);
        RAIN_DROPS_COUNT_PREVIOUS = RAIN_DROPS_COUNT_CURRENT;
        generateStartAndVelocityValues();
    }

    private void OnRenderObject()
    {

        RAIN_DROPS_COUNT_CURRENT = (int)Mathf.Ceil(RainSize * DropsPerUnit * RainSize * DropsPerUnit * Density);

        if (RAIN_DROPS_COUNT_CURRENT != RAIN_DROPS_COUNT_PREVIOUS)
        {
            RAIN_DROPS_COUNT_PREVIOUS = RAIN_DROPS_COUNT_CURRENT;
            generateStartAndVelocityValues();
        }

        // Check whether Compute Shaders are Supported
        if (!SystemInfo.supportsComputeShaders)
        {
            Debug.LogWarning("For Compute-Shaders to work, You need DirectX10 or higher.");
            return;
        }

        if (isRunning)
        {
            Dispatch();
        }
    }

    void InitializeBuffers()
    {
        // Allocate Buffers
        startPointBuffer = new ComputeBuffer(RAIN_DROPS_COUNT_CURRENT, 4);
        frameTimeBuffer = new ComputeBuffer(1, 4);
        velocitiesBuffer = new ComputeBuffer(RAIN_DROPS_COUNT_CURRENT, 8);
        outputBuffer1 = new ComputeBuffer(RAIN_DROPS_COUNT_CURRENT, 12);
        outputBuffer2 = new ComputeBuffer(RAIN_DROPS_COUNT_CURRENT, 12);

        
    }

    void generateStartAndVelocityValues()
    {
        // Generate Starting Y Value for each Drop
        startOffsets = new float[RAIN_DROPS_COUNT_CURRENT];
        dropVelocities = new Vector2[RAIN_DROPS_COUNT_CURRENT];

        for (int i = 0; i < RAIN_DROPS_COUNT_CURRENT; i++)
        {
            // Calculate Random StartOffsets for each Drop
            startOffsets[i] = Random.value * 6;
            // Calculate Random Velocities for each Drop
            // The Velocity should at least be 0.1
            dropVelocities[i] = new Vector2(0.1f + Random.value, 0.1f + Random.value);
        }
    }

    public void Dispatch()
    {
        // Set the current Frame-Time
        // We multiply by 0.01 to get a smaller Value to Interpolate with
        // This slows down the Rain and makes it more realistic

        // Retrieve the CSMain FunctionID
        CSKernel = ComputeShader.FindKernel("CSMain");

        // Set the Velocities in the velocitiesBuffer
        velocitiesBuffer.SetData(dropVelocities);

        // Set the StartOffests in the startPointBuffer
        startPointBuffer.SetData(startOffsets);

        // Set the GameTime
        frameTimeBuffer.SetData(new[] { Time.time * .01f });

        // add the startPointBuffer to the Compute Shader
        ComputeShader.SetBuffer(CSKernel, "startPointBuffer", startPointBuffer);

        // Set the Density in start() since it has to be constant
        ComputeShader.SetFloat("_Density", Density);

        ComputeShader.SetBuffer(CSKernel, "velocitiesBuffer", velocitiesBuffer);
        ComputeShader.SetBuffer(CSKernel, "frameTimeBuffer", frameTimeBuffer);
        ComputeShader.SetBuffer(CSKernel, "outputBuffer1", outputBuffer1);
        ComputeShader.SetBuffer(CSKernel, "outputBuffer2", outputBuffer2);
        ComputeShader.SetFloat("_Speed", Speed);
        ComputeShader.SetInt("_RainHeight", RainHeight);
        ComputeShader.SetVector("_RainPosition", RainPosition);
        ComputeShader.SetInt("_RainDropsCount", RAIN_DROPS_COUNT_CURRENT);
        ComputeShader.SetInt("_RainSize", RainSize);

        int threadGroupCount = (int)Mathf.Ceil(Mathf.Sqrt(RAIN_DROPS_COUNT_CURRENT / THREADS_PER_GROUP));
        ComputeShader.SetInt("_ThreadGroupCount", threadGroupCount);

        // Dispatching of 32 * 32 * 16 * 16 Threads in 16 * 16 Thread Groups (each containing 64 Threads)
        ComputeShader.Dispatch(CSKernel, threadGroupCount, threadGroupCount, THREAD_GROUP_Z_SIZE);
    }

    private void OnDestroy()
    {
        isRunning = false;
        ReleaseBuffers();
    }

    private void OnDisable()
    {
        isRunning = false;
    }

    // Releases all Buffers
    void ReleaseBuffers()
    {
        velocitiesBuffer.Release();
        frameTimeBuffer.Release();
        startPointBuffer.Release();
        outputBuffer1.Release();
        outputBuffer2.Release();

    }

    public bool getIsRunning()
    {
        return isRunning;
    }

    public int getRainDropsCount()
    {
        return RAIN_DROPS_COUNT_CURRENT;
    }


}