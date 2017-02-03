using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DayNightCycle : MonoBehaviour {

    public GameObject sun;


    [Range(1.0f, 360.0f)]
    public float sunPosition = 120;

    [Range(-1.0f, 1.0f)]
    public float sunSpeed = 0.0f;

    [Range(0.0f, 360.0f)]
    public float sunHorizonPosition = 10;

    public Color morningColor = new Color(1.0f, 0.5f, 0.0f);
    public Color dayColor = new Color(0.95f, 1.0f, 0.75f);
    public Color evningColor = new Color(1.0f, 0.45f, 0.0f);
    public Color nightColor = new Color(0.04f, 0.19f, 0.27f);


    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

        sunPosition = sunPosition + 0.1f * sunSpeed;
        if (sunPosition > 360)
        {
            sunPosition = 1;
        }else if(sunPosition < 1)
        {
            sunPosition = 360;
        }

        sun.transform.rotation = Quaternion.identity;
        sun.transform.Rotate(new Vector3(0, 1, 0), sunHorizonPosition, Space.World);
        sun.transform.Rotate(new Vector3(1, 0, 0), -90, Space.Self);
        sun.transform.Rotate(new Vector3(1, 0, 0), sunPosition, Space.Self);

        Light light = sun.GetComponent<Light>();
        light.color = calculateLightColor(sunPosition);
    }

    Color calculateLightColor(float sunPosition)
    {
        Color color = nightColor;
        if (sunPosition <= 90)
        {
            color = lerp(nightColor, morningColor, sunPosition / 90.0f);
        }
        else if (sunPosition <= 180)
        {
            color = lerp(morningColor, dayColor, (sunPosition - 90) / 90.0f);

        }
        else if (sunPosition <= 270)
        {
            color = lerp(dayColor, evningColor, (sunPosition - 180) / 90.0f);

        }
        else if (sunPosition <= 360)
        {
            color = lerp(evningColor, nightColor, (sunPosition - 270) / 90.0f);

        }

        return color;
    }

    Vector4 lerp(Vector4 a, Vector4 b, float w)
    {
        return a + (b - a) * w;
    }
}
