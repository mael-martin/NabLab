/**
 */
package fr.cea.nabla.ir.ir;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Task Dependency Variable</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getConnectivityName <em>Connectivity Name</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getIndexType <em>Index Type</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getIndex <em>Index</em>}</li>
 * </ul>
 *
 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskDependencyVariable()
 * @model
 * @generated
 */
public interface TaskDependencyVariable extends Variable {
	/**
	 * Returns the value of the '<em><b>Connectivity Name</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Connectivity Name</em>' attribute.
	 * @see #setConnectivityName(String)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskDependencyVariable_ConnectivityName()
	 * @model required="true"
	 * @generated
	 */
	String getConnectivityName();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getConnectivityName <em>Connectivity Name</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Connectivity Name</em>' attribute.
	 * @see #getConnectivityName()
	 * @generated
	 */
	void setConnectivityName(String value);

	/**
	 * Returns the value of the '<em><b>Index Type</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Index Type</em>' attribute.
	 * @see #setIndexType(String)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskDependencyVariable_IndexType()
	 * @model required="true"
	 * @generated
	 */
	String getIndexType();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getIndexType <em>Index Type</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Index Type</em>' attribute.
	 * @see #getIndexType()
	 * @generated
	 */
	void setIndexType(String value);

	/**
	 * Returns the value of the '<em><b>Index</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Index</em>' attribute.
	 * @see #setIndex(int)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskDependencyVariable_Index()
	 * @model required="true"
	 * @generated
	 */
	int getIndex();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getIndex <em>Index</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Index</em>' attribute.
	 * @see #getIndex()
	 * @generated
	 */
	void setIndex(int value);

} // TaskDependencyVariable
