package explicitheatequation;

import java.util.HashMap;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.stream.IntStream;

import fr.cea.nabla.javalib.Utils;
import fr.cea.nabla.javalib.types.*;
import fr.cea.nabla.javalib.mesh.*;

@SuppressWarnings("all")
public final class ExplicitHeatEquation
{
	public final static class Options
	{
		public final double X_LENGTH = 2.0;
		public final double Y_LENGTH = 2.0;
		public final double u0 = 1.0;
		public final double[] vectOne = {1.0,1.0};
		public final int X_EDGE_ELEMS = 40;
		public final int Y_EDGE_ELEMS = 40;
		public final int Z_EDGE_ELEMS = 1;
		public final double X_EDGE_LENGTH = X_LENGTH / X_EDGE_ELEMS;
		public final double Y_EDGE_LENGTH = Y_LENGTH / Y_EDGE_ELEMS;
		public final double option_stoptime = 1.0;
		public final int option_max_iterations = 500000000;
	}
	
	private final Options options;

	// Mesh
	private final NumericMesh2D mesh;
	private final int nbNodes, nbCells, nbFaces, nbNodesOfCell, nbNodesOfFace, nbCellsOfFace, nbNeighbourCells;
	private final VtkFileWriter2D writer;

	// Global Variables
	private double t, deltat, t_nplus1;

	// Array Variables
	private double[] X[];
	private double[] Xc[];
	private double xc[];
	private double yc[];
	private double u[];
	private double V[];
	private double D[];
	private double faceLength[];
	private double faceConductivity[];
	private double alpha[][];
	private double u_nplus1[];
	
	public ExplicitHeatEquation(Options aOptions, NumericMesh2D aNumericMesh2D)
	{
		options = aOptions;
		mesh = aNumericMesh2D;
		writer = new VtkFileWriter2D("ExplicitHeatEquation");

		nbNodes = mesh.getNbNodes();
		nbCells = mesh.getNbCells();
		nbFaces = mesh.getNbFaces();
		nbNodesOfCell = NumericMesh2D.MaxNbNodesOfCell;
		nbNodesOfFace = NumericMesh2D.MaxNbNodesOfFace;
		nbCellsOfFace = NumericMesh2D.MaxNbCellsOfFace;
		nbNeighbourCells = NumericMesh2D.MaxNbNeighbourCells;

		t = 0.0;
		deltat = 0.001;
		t_nplus1 = 0.0;

		// Arrays allocation
		X = new double[nbNodes][2];
		Xc = new double[nbCells][2];
		xc = new double[nbCells];
		yc = new double[nbCells];
		u = new double[nbCells];
		V = new double[nbCells];
		D = new double[nbCells];
		faceLength = new double[nbFaces];
		faceConductivity = new double[nbFaces];
		alpha = new double[nbCells][nbCells];
		u_nplus1 = new double[nbCells];

		// Copy node coordinates
		ArrayList<double[]> gNodes = mesh.getGeometricMesh().getNodes();
		IntStream.range(0, nbNodes).parallel().forEach(rNodes -> X[rNodes] = gNodes.get(rNodes));
	}

	public void simulate()
	{
		System.out.println("Début de l'exécution du module ExplicitHeatEquation");
		initXc(); // @-3.0
		initD(); // @-3.0
		computeV(); // @-3.0
		computeFaceLength(); // @-3.0
		initXcAndYc(); // @-2.0
		initU(); // @-2.0
		computeDeltaTn(); // @-2.0
		computeFaceConductivity(); // @-2.0
		computeAlphaCoeff(); // @-1.0

		int iteration = 0;
		while (t < options.option_stoptime && iteration < options.option_max_iterations)
		{
			iteration++;
			System.out.println("[" + iteration + "] t = " + t);
			dumpVariables(iteration);
			updateU(); // @1.0
			computeTn(); // @1.0
			copy_u_nplus1_to_u(); // @2.0
			copy_t_nplus1_to_t(); // @2.0
		}
		dumpVariables(iteration);
		System.out.println("Fin de l'exécution du module ExplicitHeatEquation");
	}

	public static void main(String[] args)
	{
		ExplicitHeatEquation.Options o = new ExplicitHeatEquation.Options();
		Mesh<double[]> gm = CartesianMesh2DGenerator.generate(o.X_EDGE_ELEMS, o.Y_EDGE_ELEMS, o.X_EDGE_LENGTH, o.Y_EDGE_LENGTH);
		NumericMesh2D nm = new NumericMesh2D(gm);
		ExplicitHeatEquation i = new ExplicitHeatEquation(o, nm);
		i.simulate();
	}
	
	private void dumpVariables(int iteration)
	{
		HashMap<String, double[]> cellVariables = new HashMap<String, double[]>();
		HashMap<String, double[]> nodeVariables = new HashMap<String, double[]>();
		cellVariables.put("Temperature", u);
		writer.writeFile(iteration, X, mesh.getGeometricMesh().getQuads(), cellVariables, nodeVariables);
	}

	/**
	 * Job InitXc @-3.0
	 * In variables: X
	 * Out variables: Xc
	 */
	private void initXc() 
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			int cId = cCells;
			double[] reduceSum9574393 = {0.0,0.0};
			{
				int[] nodesOfCellC = mesh.getNodesOfCell(cId);
				for (int pNodesOfCellC=0; pNodesOfCellC<nodesOfCellC.length; pNodesOfCellC++)
				{
					int pId = nodesOfCellC[pNodesOfCellC];
					int pNodes = pId;
					reduceSum9574393 = OperatorExtensions.operator_plus(reduceSum9574393, (X[pNodes]));
				}
			}
			Xc[cCells] = OperatorExtensions.operator_multiply(0.25, reduceSum9574393);
		});
	}		
	
	/**
	 * Job InitD @-3.0
	 * In variables: 
	 * Out variables: D
	 */
	private void initD() 
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			D[cCells] = 1.0;
		});
	}		
	
	/**
	 * Job ComputeV @-3.0
	 * In variables: X
	 * Out variables: V
	 */
	private void computeV() 
	{
		IntStream.range(0, nbCells).parallel().forEach(jCells -> 
		{
			int jId = jCells;
			double reduceSum_236982947 = 0.0;
			{
				int[] nodesOfCellJ = mesh.getNodesOfCell(jId);
				for (int pNodesOfCellJ=0; pNodesOfCellJ<nodesOfCellJ.length; pNodesOfCellJ++)
				{
					int pId = nodesOfCellJ[pNodesOfCellJ];
					int pPlus1Id = nodesOfCellJ[(pNodesOfCellJ+1+nbNodesOfCell)%nbNodesOfCell];
					int pNodes = pId;
					int pPlus1Nodes = pPlus1Id;
					reduceSum_236982947 = reduceSum_236982947 + (MathFunctions.det(X[pNodes], X[pPlus1Nodes]));
				}
			}
			V[jCells] = 0.5 * reduceSum_236982947;
		});
	}		
	
	/**
	 * Job ComputeFaceLength @-3.0
	 * In variables: X
	 * Out variables: faceLength
	 */
	private void computeFaceLength() 
	{
		IntStream.range(0, nbFaces).parallel().forEach(fFaces -> 
		{
			int fId = fFaces;
			double reduceSum505189429 = 0.0;
			{
				int[] nodesOfFaceF = mesh.getNodesOfFace(fId);
				for (int pNodesOfFaceF=0; pNodesOfFaceF<nodesOfFaceF.length; pNodesOfFaceF++)
				{
					int pId = nodesOfFaceF[pNodesOfFaceF];
					int pPlus1Id = nodesOfFaceF[(pNodesOfFaceF+1+nbNodesOfFace)%nbNodesOfFace];
					int pNodes = pId;
					int pPlus1Nodes = pPlus1Id;
					reduceSum505189429 = reduceSum505189429 + (MathFunctions.norm(OperatorExtensions.operator_minus(X[pNodes], X[pPlus1Nodes])));
				}
			}
			faceLength[fFaces] = 0.5 * reduceSum505189429;
		});
	}		
	
	/**
	 * Job InitXcAndYc @-2.0
	 * In variables: Xc
	 * Out variables: xc, yc
	 */
	private void initXcAndYc() 
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			xc[cCells] = Xc[cCells][0];
			yc[cCells] = Xc[cCells][1];
		});
	}		
	
	/**
	 * Job InitU @-2.0
	 * In variables: Xc, vectOne, u0
	 * Out variables: u
	 */
	private void initU() 
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			if (MathFunctions.norm(OperatorExtensions.operator_minus(Xc[cCells], options.vectOne)) < 0.5) 
				u[cCells] = options.u0;
			else 
				u[cCells] = 0.0;
		});
	}		
	
	/**
	 * Job computeDeltaTn @-2.0
	 * In variables: X_EDGE_LENGTH, Y_EDGE_LENGTH, D
	 * Out variables: deltat
	 */
	private void computeDeltaTn() 
	{
		double reduceMin_1282422837 = IntStream.range(0, nbCells).boxed().parallel().reduce(
			Double.MAX_VALUE, 
			(r, cCells) -> MathFunctions.reduceMin(r, options.X_EDGE_LENGTH * options.Y_EDGE_LENGTH / D[cCells]),
			(r1, r2) -> MathFunctions.reduceMin(r1, r2)
		);
		deltat = reduceMin_1282422837 * 0.24;
	}		
	
	/**
	 * Job ComputeFaceConductivity @-2.0
	 * In variables: D
	 * Out variables: faceConductivity
	 */
	private void computeFaceConductivity() 
	{
		IntStream.range(0, nbFaces).parallel().forEach(fFaces -> 
		{
			int fId = fFaces;
			double reduceProd_1688659495 = 1.0;
			{
				int[] cellsOfFaceF = mesh.getCellsOfFace(fId);
				for (int c1CellsOfFaceF=0; c1CellsOfFaceF<cellsOfFaceF.length; c1CellsOfFaceF++)
				{
					int c1Id = cellsOfFaceF[c1CellsOfFaceF];
					int c1Cells = c1Id;
					reduceProd_1688659495 = reduceProd_1688659495 * (D[c1Cells]);
				}
			}
			double reduceSum1410943609 = 0.0;
			{
				int[] cellsOfFaceF = mesh.getCellsOfFace(fId);
				for (int c2CellsOfFaceF=0; c2CellsOfFaceF<cellsOfFaceF.length; c2CellsOfFaceF++)
				{
					int c2Id = cellsOfFaceF[c2CellsOfFaceF];
					int c2Cells = c2Id;
					reduceSum1410943609 = reduceSum1410943609 + (D[c2Cells]);
				}
			}
			faceConductivity[fFaces] = 2.0 * reduceProd_1688659495 / reduceSum1410943609;
		});
	}		
	
	/**
	 * Job computeAlphaCoeff @-1.0
	 * In variables: deltat, V, faceLength, faceConductivity, Xc
	 * Out variables: alpha
	 */
	private void computeAlphaCoeff() 
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			int cId = cCells;
			double alphaDiag = 0.0;
			{
				int[] neighbourCellsC = mesh.getNeighbourCells(cId);
				for (int dNeighbourCellsC=0; dNeighbourCellsC<neighbourCellsC.length; dNeighbourCellsC++)
				{
					int dId = neighbourCellsC[dNeighbourCellsC];
					int dCells = dId;
					int fId = mesh.getCommonFace(cId, dId);
					int fFaces = fId;
					double alphaExtraDiag = deltat / V[cCells] * (faceLength[fFaces] * faceConductivity[fFaces]) / MathFunctions.norm(OperatorExtensions.operator_minus(Xc[cCells], Xc[dCells]));
					alpha[cCells][dCells] = alphaExtraDiag;
					alphaDiag = alphaDiag + alphaExtraDiag;
				}
			}
			alpha[cCells][cCells] = 1 - alphaDiag;
		});
	}		
	
	/**
	 * Job UpdateU @1.0
	 * In variables: alpha, u
	 * Out variables: u_nplus1
	 */
	private void updateU() 
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			int cId = cCells;
			double reduceSum_745417239 = 0.0;
			{
				int[] neighbourCellsC = mesh.getNeighbourCells(cId);
				for (int dNeighbourCellsC=0; dNeighbourCellsC<neighbourCellsC.length; dNeighbourCellsC++)
				{
					int dId = neighbourCellsC[dNeighbourCellsC];
					int dCells = dId;
					reduceSum_745417239 = reduceSum_745417239 + (alpha[cCells][dCells] * u[dCells]);
				}
			}
			u_nplus1[cCells] = alpha[cCells][cCells] * u[cCells] + reduceSum_745417239;
		});
	}		
	
	/**
	 * Job ComputeTn @1.0
	 * In variables: t, deltat
	 * Out variables: t_nplus1
	 */
	private void computeTn() 
	{
		t_nplus1 = t + deltat;
	}		
	
	/**
	 * Job Copy_u_nplus1_to_u @2.0
	 * In variables: u_nplus1
	 * Out variables: u
	 */
	private void copy_u_nplus1_to_u() 
	{
		double[] tmpSwitch = u;
		u = u_nplus1;
		u_nplus1 = tmpSwitch;
	}		
	
	/**
	 * Job Copy_t_nplus1_to_t @2.0
	 * In variables: t_nplus1
	 * Out variables: t
	 */
	private void copy_t_nplus1_to_t() 
	{
		double tmpSwitch = t;
		t = t_nplus1;
		t_nplus1 = tmpSwitch;
	}		
};
