using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkyDomeScript : MonoBehaviour {

    public Transform skyDomeCamera;
    public GameObject sunLight;
    private Vector3 sunLightDirection;

    public Texture2D fewCloudsTexture;
    public Texture2D manyCloudsTexture;

    [Range(0.0f, 1.0f)]
    public float weather = 1.0f;

    [Range(0.0f, 1.0f)]
    public float cloudSpeed = 1.0f;

    private float cloudAlpha;
    
    private Color waveLength;
    private Color invWaveLength; 

    private float cameraHeight;
    private float cameraHeight2;

    public float outerRadius = 2454;

    public float innerRadius = 2437.5f;

    public float rayleighConstant = 0.0013f;
    public float mieConstant = 0.00001f;

    public float sunBrightness = 25.5f;

    private float scale;
    public float scaleDepth = 1.2f;

    private float scaleOverScaleDepth;

    public float nSamples = 12;

    public float symmetryConstant = -0.990f;

    Material material;

    void Start () {

        sunLightDirection = sunLight.transform.TransformDirection(-Vector3.forward);

        // Wavelengths
        waveLength = new Color(0.650f, 0.550f, 0.440f, 1);
        invWaveLength = new Color(pow(waveLength[0], 4), pow(waveLength[1], 4), pow(waveLength[2], 4), 1);

        cameraHeight = skyDomeCamera.position.magnitude;
        cameraHeight2 = cameraHeight * cameraHeight;

        DayNightCycle dayNightScript = GetComponent<DayNightCycle>();
        float sunPosition = dayNightScript.sunPosition;
        cloudAlpha = calculateCloudAlpha(sunPosition);

        material = GetComponent<MeshRenderer>().sharedMaterial;

    }

    // Update is called once per frame
    void Update() {

        sunLightDirection = sunLight.transform.TransformDirection(-Vector3.forward);
        cameraHeight = skyDomeCamera.position.magnitude;
        cameraHeight2 = cameraHeight * cameraHeight;

        DayNightCycle dayNightScript = GetComponent<DayNightCycle>();
        float sunPosition = dayNightScript.sunPosition;
        cloudAlpha = calculateCloudAlpha(sunPosition);

        material.SetVector("_CameraPosition", new Vector4(skyDomeCamera.position.x, skyDomeCamera.position.y, skyDomeCamera.position.z, 0));
        material.SetVector("_LightDirection", new Vector4(sunLightDirection.x, sunLightDirection.y, sunLightDirection.z, 0));
        material.SetColor("_InvWaveLength", invWaveLength);
        material.SetFloat("_CameraHeight", cameraHeight);
        material.SetFloat("_CameraHeight2", cameraHeight2);
        material.SetFloat("_OuterRadius", outerRadius);
        material.SetFloat("_InnerRadius", innerRadius);
        material.SetFloat("_RayleighConstant", rayleighConstant);
        material.SetFloat("_MieConstant", mieConstant);
        material.SetFloat("_SunBrightness", sunBrightness);
        material.SetFloat("_ScaleDepth", scaleDepth);
        material.SetFloat("_NSamples", nSamples);
        material.SetFloat("_SymmetryConstant", symmetryConstant);

        material.SetTexture("_FewClouds", fewCloudsTexture);
        material.SetTexture("_ManyClouds", manyCloudsTexture);
        material.SetFloat("_CloudAlpha", cloudAlpha);
        material.SetFloat("_GameTime", Time.time * cloudSpeed * 0.005f);
        material.SetFloat("_LightDim", weather);
    }

    float calculateCloudAlpha(float sunPosition)
    {
        float alpha = 0f;
        float maxAlpha = 0.6f;

        if (sunPosition <= 60)
        {
            alpha = lerp(0, 0, 0);
        }
        else if(sunPosition <= 80)
        {
            alpha = lerp(-0.21f, -0.1115f, map(sunPosition, 60, 80, 0, 1));
        }
        else if (sunPosition <= 86)
        {
            alpha = lerp(-0.1115f, 0.25f, map(sunPosition, 80, 86, 0f, 1f));
        }
        else if (sunPosition <= 100)
        {
            alpha = lerp(0.25f, maxAlpha, map(sunPosition, 86, 100, 0f, 1f));
        }
        else if (sunPosition <= 190)
        {
            alpha = maxAlpha;
        }
        else if (sunPosition <= 260)
        {
            alpha = lerp(maxAlpha, 0.25f, map(sunPosition, 190, 260, 0f, 1f));
        }
        else if (sunPosition <= 274)
        {
            alpha = lerp(0.25f, -0.1115f, map(sunPosition, 260, 274, 0f, 1f));
        }
        else if (sunPosition <= 300)
        {
            alpha = lerp(-0.1115f, -0.21f, map(sunPosition, 274, 300, 0f, 1f));
        }

        return alpha;
    }

    float map(float s, float a1, float a2, float b1, float b2)
    {
        return b1 + (s - a1) * (b2 - b1) / (a2 - a1);
    }

    float lerp(float a, float b, float w)
    {
        return a + (b - a) * w;
    }

    float pow(float f, int p)
    {
        return 1 / Mathf.Pow(f, p);
    }
}
