using UnityEngine;
using System.Collections;
using UnityEngine.Rendering;//CommandBufferを使う用
using System.Collections.Generic;



[ExecuteInEditMode]
public class RaymarchingRenderer : MonoBehaviour {

	private Dictionary<Camera, CommandBuffer> _cameras = new Dictionary<Camera, CommandBuffer>();
	private Mesh _quad;

	[SerializeField]
	private Material _material = null;

	[SerializeField] // タイミング
	private CameraEvent pass = CameraEvent.BeforeGBuffer;

	public float scale = 2.0f;
	public float scale2 = 1.0f;
	public float coeff = 1;
	public float amp = 1;
	public float ampSpan = 1;



	// study1 mesh
	Mesh GenerateQuad()
	{
		var mesh = new Mesh ();
		mesh.vertices = new Vector3[4] {
			new Vector3 (1.0f, 1.0f, 0.0f),
			new Vector3 (-1.0f, 1.0f, 0.0f),
			new Vector3 (-1.0f, -1.0f, 0.0f),
			new Vector3 (1.0f, -1.0f, 0.0f)
		};
		mesh.triangles = new int[6]{ 0, 1, 2, 2, 3, 0 };
		return mesh;
	}

	// study2 command buffer
	void CleanUp()
	{
		foreach (var pair in _cameras) {
			var camera = pair.Key;
			var buffer = pair.Value;
			if (camera) {
				camera.RemoveCommandBuffer (pass, buffer);
			}
		}
		_cameras.Clear ();
	}

	void OnEnable(){
		CleanUp ();
	}

	void OnDisable()
	{
		CleanUp ();
	}

	// オブジェクトが表示されている場合，カメラごとに１度呼ばれるイベント
	void OnWillRenderObject()
	{
		UpdateCommandBuffer ();	
	}

	void UpdateCommandBuffer()
	{
		var act = gameObject.activeInHierarchy && enabled;
		if (!act) {
			OnDisable ();
			return;
		}

		var camera = Camera.current;
		if (!camera) 
			return;

		if (_cameras.ContainsKey (camera))
			return;

		if (!_quad)
			_quad = GenerateQuad ();

		// study 3 commandbuffer
		var buffer = new CommandBuffer ();
		buffer.name = "Raymarching";
		// study 4 DrawMesh
		buffer.DrawMesh(_quad, Matrix4x4.identity, _material, 0, 0);
		// stdy5 addCommandBuffer
		camera.AddCommandBuffer(pass, buffer);
		_cameras.Add (camera, buffer);

	}

	void Update(){


		_material.SetFloat ("_Scale", scale * (1.1f + amp *Mathf.Sin(coeff * Time.time)));

		_material.SetFloat ("_Scale2", scale2);
	}
}
