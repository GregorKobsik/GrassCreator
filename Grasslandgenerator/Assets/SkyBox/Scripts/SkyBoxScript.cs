using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/**
 * Implementation of a SkyDome with ideas from the following paper:
 * http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.89.7917&rep=rep1&type=pdf
 * 
 * */
public class SkyBoxScript : MonoBehaviour {

    [Range(1.0f, 720.0f)]
    public float dayNight = 1;

    [Range(-1.0f, 1.0f)]
    public float sunSpeed = 0.5f;

    [Range(0.0f, 1.0f)]
    public float cloudSpeed = 1.0f;

    int meshScale = 128;
    public int skyBoxRadius = 200;

    [Range(0.01f, 0.09f)]
    public float sunSizeDay = 0.04f;

    [Range(0.01f, 0.2f)]
    public float sunSizeDawn = 0.2f;

    public Vector3 skyBoxPosition = new Vector3(0, 0, 0);

    Vector3 sunPosition;

    public Vector3 debugPos;

    MeshRenderer mr;
    public Material skyBoxMaterial;

    GameObject sphere;
    GameObject directionalLight;

    public Color morningColor = new Color(1.0f, 0.5f, 0.0f);
    public Color dayColor = new Color(0.95f, 1.0f, 0.75f);
    public Color evningColor = new Color(1.0f, 0.45f, 0.0f);
    public Color nightColor = new Color(0.04f, 0.19f, 0.27f);

    void Start () {

        skyBoxPosition = new Vector3(meshScale / 2, 0, meshScale / 2);

        sunPosition = new Vector3(0 , -skyBoxRadius, 0);
        debugPos = new Vector3(0, -skyBoxRadius, 0);

        sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.position = skyBoxPosition;
        sphere.transform.localScale = new Vector3(skyBoxRadius * 2, skyBoxRadius * 2, skyBoxRadius * 2);
        sphere.transform.parent = transform;

        directionalLight = GameObject.Find("Directional Light");
        directionalLight.transform.rotation = Quaternion.identity; ;
        directionalLight.transform.Rotate(new Vector3(0,1,0), 90, Space.World);
        directionalLight.transform.Rotate(new Vector3(0,0,1), 90, Space.World);

        mr = sphere.GetComponent<MeshRenderer>();
        mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
        mr.receiveShadows = false;
        mr.motionVectorGenerationMode = MotionVectorGenerationMode.ForceNoMotion;

        //Vector3 pos = new Vector3(meshScale / 2, 0, meshScale / 2);
        //transform.position = pos;
    }

    float lerp(float a, float b, float w)
    {
        return a + (b - a) * w;
    }

    Vector4 lerp(Vector4 a, Vector4 b, float w)
    {
        return a + (b - a) * w;
    }

    // Update is called once per frame
    void Update () {

        dayNight = dayNight + 0.5f * sunSpeed;
        if(dayNight >= 720)
        {
            dayNight = 1;
        }

        Vector3 sunpos = Quaternion.AngleAxis(dayNight/2, new Vector3(0, 0, 1)) * sunPosition;
        // prevents gradient clipping on 90 degrees
        // dont know how to fix this yet
        if(sunpos.x <= 14 && sunpos.x >= 0)
        {
            sunpos.x = 14;
        }else if(sunpos.x <= 0 && sunpos.x > -14)
        {
            sunpos.x = -14;
        }
        debugPos = sunpos;

        directionalLight.transform.rotation = Quaternion.identity; ;
        directionalLight.transform.Rotate(new Vector3(0, 1, 0), 90, Space.World);
        directionalLight.transform.Rotate(new Vector3(0, 0, 1), 90, Space.World);
        directionalLight.transform.Rotate(new Vector3(0, 0, 1), dayNight/2, Space.World);
        Light light = directionalLight.GetComponent<Light>();
        light.color = calculateLightColor(dayNight / 2);

        skyBoxMaterial.SetFloat("_GameTime", Time.time * cloudSpeed * 0.005f);
        skyBoxMaterial.SetFloat("_SkyBoxRadius", skyBoxRadius);
        skyBoxMaterial.SetVector("_SunPosition", sunpos);
        skyBoxMaterial.SetFloat("_SunSizeDay", sunSizeDay);
        skyBoxMaterial.SetFloat("_SunSizeDawn", sunSizeDawn);

        mr.material = skyBoxMaterial;
	}


    Color calculateLightColor(float dayNight)
    {
        Color color = nightColor;
        if (dayNight <= 90)
        {
            color = lerp(nightColor, morningColor, dayNight / 90.0f);
        }else if (dayNight <= 180)
        {
            color = lerp(morningColor, dayColor, (dayNight - 90) / 90.0f);

        }else if (dayNight <= 270)
        {
            color = lerp(dayColor, evningColor, (dayNight - 180) / 90.0f);

        }else if(dayNight <= 360)
        {
            color = lerp(evningColor, nightColor, (dayNight - 270) / 90.0f);

        }

        return color;
    }
}
