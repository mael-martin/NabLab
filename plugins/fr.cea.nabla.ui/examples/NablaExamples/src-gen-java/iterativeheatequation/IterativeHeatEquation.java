package iterativeheatequation;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.stream.IntStream;

import fr.cea.nabla.javalib.types.*;
import fr.cea.nabla.javalib.mesh.*;

@SuppressWarnings("all")
public final class IterativeHeatEquation
{
	public final static class Options
	{
		public final double X_LENGTH = 2.0;
		public final double Y_LENGTH = 2.0;
		public final double u0 = 1.0;
		public final double[] vectOne = {1.0, 1.0};
		public final int X_EDGE_ELEMS = 40;
		public final int Y_EDGE_ELEMS = 40;
		public final int Z_EDGE_ELEMS = 1;
		public final double X_EDGE_LENGTH = X_LENGTH / X_EDGE_ELEMS;
		public final double Y_EDGE_LENGTH = Y_LENGTH / Y_EDGE_ELEMS;
		public final double option_stoptime = 0.1;
		public final int option_max_iterations = 500000000;
		public final int option_max_iterations_k = 1000;
	}

	private final Options options;

	// Mesh
	private final NumericMesh2D mesh;
	private final FileWriter writer;
	private final int nbNodes, nbCells, nbFaces, nbNodesOfCell, nbNodesOfFace, nbCellsOfFace, nbNeighbourCells;

	// Global Variables
	private double t_n, t_nplus1, deltat, epsilon, residual;
	private int iterationN, iterationK, lastDump;

	// Connectivity Variables
	private double[][] X, Xc, alpha;
	private double[] xc, yc, u_n, u_nplus1, u_nplus1_k, u_nplus1_kplus1, V, D, faceLength, faceConductivity;

	public IterativeHeatEquation(Options aOptions, NumericMesh2D aNumericMesh2D)
	{
		options = aOptions;
		mesh = aNumericMesh2D;
		writer = new PvdFileWriter2D("IterativeHeatEquation");
		nbNodes = mesh.getNbNodes();
		nbCells = mesh.getNbCells();
		nbFaces = mesh.getNbFaces();
		nbNodesOfCell = NumericMesh2D.MaxNbNodesOfCell;
		nbNodesOfFace = NumericMesh2D.MaxNbNodesOfFace;
		nbCellsOfFace = NumericMesh2D.MaxNbCellsOfFace;
		nbNeighbourCells = NumericMesh2D.MaxNbNeighbourCells;

		t_n = 0.0;
		t_nplus1 = 0.0;
		deltat = 0.001;
		epsilon = 1.0E-8;
		residual = epsilon + 1.0;
		lastDump = iterationN;

		// Allocate arrays
		X = new double[nbNodes][2];
		Xc = new double[nbCells][2];
		xc = new double[nbCells];
		yc = new double[nbCells];
		u_n = new double[nbCells];
		u_nplus1 = new double[nbCells];
		u_nplus1_k = new double[nbCells];
		u_nplus1_kplus1 = new double[nbCells];
		V = new double[nbCells];
		D = new double[nbCells];
		faceLength = new double[nbFaces];
		faceConductivity = new double[nbFaces];
		alpha = new double[nbCells][nbCells];

		// Copy node coordinates
		ArrayList<double[]> gNodes = mesh.getGeometricMesh().getNodes();
		IntStream.range(0, nbNodes).parallel().forEach(rNodes -> X[rNodes] = gNodes.get(rNodes));
	}

	public void simulate()
	{
		System.out.println("Début de l'exécution du module IterativeHeatEquation");
		initXc(); // @1.0
		initD(); // @1.0
		computeV(); // @1.0
		computeFaceLength(); // @1.0
		initXcAndYc(); // @2.0
		initU(); // @2.0
		computeDeltaTn(); // @2.0
		computeFaceConductivity(); // @2.0
		computeAlphaCoeff(); // @3.0
		executeTimeLoopN(); // @4.0
		System.out.println("Fin de l'exécution du module IterativeHeatEquation");
	}

	public static void main(String[] args)
	{
		IterativeHeatEquation.Options o = new IterativeHeatEquation.Options();
		Mesh gm = CartesianMesh2DGenerator.generate(o.X_EDGE_ELEMS, o.Y_EDGE_ELEMS, o.X_EDGE_LENGTH, o.Y_EDGE_LENGTH);
		NumericMesh2D nm = new NumericMesh2D(gm);
		IterativeHeatEquation i = new IterativeHeatEquation(o, nm);
		i.simulate();
	}

	/**
	 * Job setUpTimeLoopK called @1.0 in executeTimeLoopN method.
	 * In variables: u_n
	 * Out variables: u_nplus1_k
	 */
	private void setUpTimeLoopK()
	{
		IntStream.range(0, u_nplus1_k.length).parallel().forEach(i1 -> 
		{
			u_nplus1_k[i1] = u_n[i1];
		});
	}

	/**
	 * Job InitXc called @1.0 in simulate method.
	 * In variables: X
	 * Out variables: Xc
	 */
	private void initXc()
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			int cId = cCells;
			double[] reduction0 = {0.0, 0.0};
			{
				int[] nodesOfCellC = mesh.getNodesOfCell(cId);
				for (int pNodesOfCellC=0; pNodesOfCellC<nodesOfCellC.length; pNodesOfCellC++)
				{
					int pId = nodesOfCellC[pNodesOfCellC];
					int pNodes = pId;
					reduction0 = ArrayOperations.plus(reduction0, (X[pNodes]));
				}
			}
			Xc[cCells] = ArrayOperations.multiply(0.25, reduction0);
		});
	}

	/**
	 * Job InitD called @1.0 in simulate method.
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
	 * Job ComputeV called @1.0 in simulate method.
	 * In variables: X
	 * Out variables: V
	 */
	private void computeV()
	{
		IntStream.range(0, nbCells).parallel().forEach(jCells -> 
		{
			int jId = jCells;
			double reduction2 = 0.0;
			{
				int[] nodesOfCellJ = mesh.getNodesOfCell(jId);
				for (int pNodesOfCellJ=0; pNodesOfCellJ<nodesOfCellJ.length; pNodesOfCellJ++)
				{
					int pId = nodesOfCellJ[pNodesOfCellJ];
					int pPlus1Id = nodesOfCellJ[(pNodesOfCellJ+1+nbNodesOfCell)%nbNodesOfCell];
					int pNodes = pId;
					int pPlus1Nodes = pPlus1Id;
					reduction2 = reduction2 + (MathFunctions.det(X[pNodes], X[pPlus1Nodes]));
				}
			}
			V[jCells] = 0.5 * reduction2;
		});
	}

	/**
	 * Job ComputeFaceLength called @1.0 in simulate method.
	 * In variables: X
	 * Out variables: faceLength
	 */
	private void computeFaceLength()
	{
		IntStream.range(0, nbFaces).parallel().forEach(fFaces -> 
		{
			int fId = fFaces;
			double reduction3 = 0.0;
			{
				int[] nodesOfFaceF = mesh.getNodesOfFace(fId);
				for (int pNodesOfFaceF=0; pNodesOfFaceF<nodesOfFaceF.length; pNodesOfFaceF++)
				{
					int pId = nodesOfFaceF[pNodesOfFaceF];
					int pPlus1Id = nodesOfFaceF[(pNodesOfFaceF+1+nbNodesOfFace)%nbNodesOfFace];
					int pNodes = pId;
					int pPlus1Nodes = pPlus1Id;
					reduction3 = reduction3 + (MathFunctions.norm(ArrayOperations.minus(X[pNodes], X[pPlus1Nodes])));
				}
			}
			faceLength[fFaces] = 0.5 * reduction3;
		});
	}

	/**
	 * Job UpdateU called @1.0 in executeTimeLoopK method.
	 * In variables: alpha, u_nplus1_k, u_n
	 * Out variables: u_nplus1_kplus1
	 */
	private void updateU()
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			int cId = cCells;
			double reduction6 = 0.0;
			{
				int[] neighbourCellsC = mesh.getNeighbourCells(cId);
				for (int dNeighbourCellsC=0; dNeighbourCellsC<neighbourCellsC.length; dNeighbourCellsC++)
				{
					int dId = neighbourCellsC[dNeighbourCellsC];
					int dCells = dId;
					reduction6 = reduction6 + (alpha[cCells][dCells] * u_nplus1_k[dCells]);
				}
			}
			u_nplus1_kplus1[cCells] = u_n[cCells] + alpha[cCells][cCells] * u_nplus1_k[cCells] + reduction6;
		});
	}

	/**
	 * Job ComputeTn called @1.0 in executeTimeLoopN method.
	 * In variables: t_n, deltat
	 * Out variables: t_nplus1
	 */
	private void computeTn()
	{
		t_nplus1 = t_n + deltat;
	}

	/**
	 * Job dumpVariables called @1.0 in executeTimeLoopN method.
	 * In variables: u_n, iterationN
	 * Out variables: 
	 */
	private void dumpVariables()
	{
		if (iterationN >= lastDump)
		{
			HashMap<String, double[]> cellVariables = new HashMap<String, double[]>();
			HashMap<String, double[]> nodeVariables = new HashMap<String, double[]>();
			cellVariables.put("Temperature", u_n);
			writer.writeFile(iterationN, t_n, X, mesh.getGeometricMesh().getQuads(), cellVariables, nodeVariables);
			lastDump = iterationN;
		}
	}

	/**
	 * Job executeTimeLoopK called @2.0 in executeTimeLoopN method.
	 * In variables: u_nplus1_kplus1, u_nplus1_k, u_n, alpha
	 * Out variables: u_nplus1_kplus1, residual
	 */
	private void executeTimeLoopK()
	{
		iterationK = 0;
		do
		{
			iterationK++;
			System.out.println("	[iterationK : " + iterationK + "] t : " + t_n);
			updateU(); // @1.0
			computeResidual(); // @2.0
		
			// Switch variables to prepare next iteration
			double[] tmpU_nplus1_k = u_nplus1_k;
			u_nplus1_k = u_nplus1_kplus1;
			u_nplus1_kplus1 = tmpU_nplus1_k;
		} while ((residual > epsilon && iterationK < options.option_max_iterations_k));
	}

	/**
	 * Job InitXcAndYc called @2.0 in simulate method.
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
	 * Job InitU called @2.0 in simulate method.
	 * In variables: Xc, vectOne, u0
	 * Out variables: u_n
	 */
	private void initU()
	{
		IntStream.range(0, nbCells).parallel().forEach(cCells -> 
		{
			if (MathFunctions.norm(ArrayOperations.minus(Xc[cCells], options.vectOne)) < 0.5) 
				u_n[cCells] = options.u0;
			else 
				u_n[cCells] = 0.0;
		});
	}

	/**
	 * Job computeDeltaTn called @2.0 in simulate method.
	 * In variables: X_EDGE_LENGTH, Y_EDGE_LENGTH, D
	 * Out variables: deltat
	 */
	private void computeDeltaTn()
	{
		double reduction1 = IntStream.range(0, nbCells).boxed().parallel().reduce(
			Double.MAX_VALUE, 
			(r, cCells) -> MathFunctions.min(r, options.X_EDGE_LENGTH * options.Y_EDGE_LENGTH / D[cCells]),
			(r1, r2) -> MathFunctions.min(r1, r2)
		);
		deltat = reduction1 * 0.1;
	}

	/**
	 * Job ComputeFaceConductivity called @2.0 in simulate method.
	 * In variables: D
	 * Out variables: faceConductivity
	 */
	private void computeFaceConductivity()
	{
		IntStream.range(0, nbFaces).parallel().forEach(fFaces -> 
		{
			int fId = fFaces;
			double reduction4 = 1.0;
			{
				int[] cellsOfFaceF = mesh.getCellsOfFace(fId);
				for (int c1CellsOfFaceF=0; c1CellsOfFaceF<cellsOfFaceF.length; c1CellsOfFaceF++)
				{
					int c1Id = cellsOfFaceF[c1CellsOfFaceF];
					int c1Cells = c1Id;
					reduction4 = reduction4 * (D[c1Cells]);
				}
			}
			double reduction5 = 0.0;
			{
				int[] cellsOfFaceF = mesh.getCellsOfFace(fId);
				for (int c2CellsOfFaceF=0; c2CellsOfFaceF<cellsOfFaceF.length; c2CellsOfFaceF++)
				{
					int c2Id = cellsOfFaceF[c2CellsOfFaceF];
					int c2Cells = c2Id;
					reduction5 = reduction5 + (D[c2Cells]);
				}
			}
			faceConductivity[fFaces] = 2.0 * reduction4 / reduction5;
		});
	}

	/**
	 * Job ComputeResidual called @2.0 in executeTimeLoopK method.
	 * In variables: u_nplus1_kplus1, u_nplus1_k
	 * Out variables: residual
	 */
	private void computeResidual()
	{
		double reduction7 = IntStream.range(0, nbCells).boxed().parallel().reduce(
			Double.MIN_VALUE, 
			(r, jCells) -> MathFunctions.max(r, MathFunctions.fabs(u_nplus1_kplus1[jCells] - u_nplus1_k[jCells])),
			(r1, r2) -> MathFunctions.max(r1, r2)
		);
		residual = reduction7;
	}

	/**
	 * Job tearDownTimeLoopK called @3.0 in executeTimeLoopN method.
	 * In variables: u_nplus1_kplus1
	 * Out variables: u_nplus1
	 */
	private void tearDownTimeLoopK()
	{
		IntStream.range(0, u_nplus1.length).parallel().forEach(i1 -> 
		{
			u_nplus1[i1] = u_nplus1_kplus1[i1];
		});
	}

	/**
	 * Job computeAlphaCoeff called @3.0 in simulate method.
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
					int fCommonFaceCD = mesh.getCommonFace(cId, dId);
					int fId = fCommonFaceCD;
					int fFaces = fId;
					double alphaExtraDiag = deltat / V[cCells] * (faceLength[fFaces] * faceConductivity[fFaces]) / MathFunctions.norm(ArrayOperations.minus(Xc[cCells], Xc[dCells]));
					alpha[cCells][dCells] = alphaExtraDiag;
					alphaDiag = alphaDiag + alphaExtraDiag;
				}
			}
			alpha[cCells][cCells] = -alphaDiag;
		});
	}

	/**
	 * Job executeTimeLoopN called @4.0 in simulate method.
	 * In variables: t_n, u_nplus1_kplus1, u_nplus1_k, iterationN, u_n, deltat, alpha
	 * Out variables: u_nplus1_kplus1, u_nplus1_k, residual, t_nplus1, u_nplus1
	 */
	private void executeTimeLoopN()
	{
		iterationN = 0;
		do
		{
			iterationN++;
			System.out.println("[iterationN : " + iterationN + "] t : " + t_n);
			setUpTimeLoopK(); // @1.0
			computeTn(); // @1.0
			dumpVariables(); // @1.0
			executeTimeLoopK(); // @2.0
			tearDownTimeLoopK(); // @3.0
		
			// Switch variables to prepare next iteration
			double tmpT_n = t_n;
			t_n = t_nplus1;
			t_nplus1 = tmpT_n;
			double[] tmpU_n = u_n;
			u_n = u_nplus1;
			u_nplus1 = tmpU_n;
		} while ((t_n < options.option_stoptime && iterationN < options.option_max_iterations));
	}
};