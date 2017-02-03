using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateGuiScript : MonoBehaviour {

    public bool isActive = false;

    public GameObject goMainCamera;
    public GameObject goGrassCreator;
    public GameObject goGeometryGrass;
    public GameObject goBillboardGrass;
    public GameObject goTerrainCreator;
    public GameObject goRain;
    public GameObject goSkyDome;

    enum View {MAIN, CAMERA, GRASS, GRASS_GEOMETRY, GRASS_BILLBOARD, TERRAIN, RAIN, SKY_DOME, PREFABS};
    View view = View.MAIN;

	// Use this for initialization
	void Start () {

	}
	
	// Update is called once per frame
	void Update () {

    }

    private void OnGUI()
    {
        switch (view)
        {
            case View.MAIN:
                createMainView();
                break;
            case View.CAMERA:
                createCameraView();
                break;
            case View.GRASS:
                createGrassView();
                break;
            case View.GRASS_GEOMETRY:
                createGrassGeometryView();
                break;
            case View.GRASS_BILLBOARD:
                createGrassBillboardView();
                break;
            case View.TERRAIN:
                createTerrainView();
                break;
            case View.RAIN:
                createRainView();
                break;
            case View.SKY_DOME:
                createSkyDomeView();
                break;
            case View.PREFABS:
                createPrefabsView();
                break;
            default:
                createMainView();
                Debug.Log("Warning: unregistered view was called!");
                break;
        }
        

    }

    private void createMainView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Settings");

        if (GUI.Button(new Rect(20, 40, 80, 20), "Camera"))
        {
            view = View.CAMERA;
        }

        if (GUI.Button(new Rect(20, 70, 80, 20), "Grass"))
        {
            view = View.GRASS;
        }

        if (GUI.Button(new Rect(20, 100, 80, 20), "Terrain"))
        {
            view = View.TERRAIN;
        }

        if (GUI.Button(new Rect(20, 130, 80, 20), "Rain"))
        {
            view = View.RAIN;
        }

        if (GUI.Button(new Rect(20, 160, 80, 20), "Sky Dome"))
        {
            view = View.SKY_DOME;
        }

        if (GUI.Button(new Rect(20, 190, 80, 20), "Prefabs"))
        {
            view = View.PREFABS;
        }
    }

    private void createCameraView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Camera");

        //Bloom Shader
        if (goMainCamera.GetComponent<UnityStandardAssets.ImageEffects.Bloom>().enabled)
        {
            if (GUI.Button(new Rect(20, 40, 80, 20), "Bloom: ON"))
            {
                goMainCamera.GetComponent<UnityStandardAssets.ImageEffects.Bloom>().enabled = false;
            }
        } else
        {
            if (GUI.Button(new Rect(20, 40, 80, 20), "Bloom: OFF"))
            {
                goMainCamera.GetComponent<UnityStandardAssets.ImageEffects.Bloom>().enabled = true;
            }
        }

        //Motion Blur Shader
        if (goMainCamera.GetComponent<UnityStandardAssets.ImageEffects.MotionBlur>().enabled)
        {
            if (GUI.Button(new Rect(20, 70, 80, 20), "Motion BLur: ON"))
            {
                goMainCamera.GetComponent<UnityStandardAssets.ImageEffects.MotionBlur>().enabled = false;
            }
        }
        else
        {
            if (GUI.Button(new Rect(20, 70, 80, 20), "Motion Blur: OFF"))
            {
                goMainCamera.GetComponent<UnityStandardAssets.ImageEffects.MotionBlur>().enabled = true;
            }
        }

    }

    private void createGrassView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Grass");
    }

    private void createGrassGeometryView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Grass: Geometry");
    }

    private void createGrassBillboardView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Grass: Billboard");
    }

    private void createTerrainView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Terrain");
    }

    private void createRainView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Rain");
    }

    private void createSkyDomeView()
    {
        GUI.Box(new Rect(10, 10, 100, 210), "Sky Dome");
    }

    private void createPrefabsView()
    {
        GUI.Box(new Rect(10, 10, 90, 220), "Prefabs");

        if (GUI.Button(new Rect(20, 40, 30, 30), "1"))
        {
            Debug.Log("1");
        }

        if (GUI.Button(new Rect(60, 40, 30, 30), "2"))
        {
            Debug.Log("2");
        }

        if (GUI.Button(new Rect(20, 80, 30, 30), "3"))
        {
            Debug.Log("3");
        }

        if (GUI.Button(new Rect(60, 80, 30, 30), "4"))
        {
            Debug.Log("4");
        }

        if (GUI.Button(new Rect(20, 120, 30, 30), "5"))
        {
            Debug.Log("5");
        }

        if (GUI.Button(new Rect(60, 120, 30, 30), "6"))
        {
            Debug.Log("6");
        }

        if (GUI.Button(new Rect(20, 160, 30, 30), "7"))
        {
            Debug.Log("7");
        }

        if (GUI.Button(new Rect(60, 160, 30, 30), "8"))
        {
            Debug.Log("8");
        }

        if (GUI.Button(new Rect(20, 200, 70, 20), "Back"))
        {
            view = View.MAIN;
        }
    }


    public void setGuiActive(bool p_isActive)
    {
        isActive = p_isActive;
        view = View.MAIN;
        gameObject.SetActive(p_isActive);
    }
}
