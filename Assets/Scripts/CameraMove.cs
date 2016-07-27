using UnityEngine;
using System.Collections;

public class CameraMove : MonoBehaviour {

	public float moveSpeed = 1.0f;
	public float rotateSpeed = 1.0f;
    
	// Use this for initialization
	void Start () {

	}
	
	// Update is called once per frame
	void Update () {
		this.transform.Rotate (Vector3.up * rotateSpeed * Time.deltaTime, Space.World);
		this.transform.position += Vector3.forward * moveSpeed;
	
	}
}
