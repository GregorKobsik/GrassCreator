using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraRotationSkydomeScript : MonoBehaviour {


    public Transform mainCamera;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        this.transform.rotation = mainCamera.rotation;
	}
}
