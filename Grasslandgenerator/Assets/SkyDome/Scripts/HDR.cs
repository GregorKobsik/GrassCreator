using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HDR : MonoBehaviour {

    public float exposure;

    Material hdrMaterial;

    // Use this for initialization
    void Start () {

        exposure = 2.0f;

        hdrMaterial = new Material(Shader.Find("Hidden/HDRShader"));
        hdrMaterial.SetFloat("_Exposure", exposure);
    }
	
	// Update is called once per frame
	void Update () {
		
	}

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        hdrMaterial.SetFloat("_Exposure", exposure);
        Graphics.Blit(source, destination, hdrMaterial);

    }
}
