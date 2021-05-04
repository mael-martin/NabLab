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
 *   <li>{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getName <em>Name</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getIndexType <em>Index Type</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getIndex <em>Index</em>}</li>
 * </ul>
 *
 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskDependencyVariable()
 * @model
 * @generated
 */
public interface TaskDependencyVariable extends IrAnnotable {
	/**
	 * Returns the value of the '<em><b>Name</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Name</em>' attribute.
	 * @see #setName(String)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskDependencyVariable_Name()
	 * @model required="true"
	 * @generated
	 */
	String getName();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getName <em>Name</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Name</em>' attribute.
	 * @see #getName()
	 * @generated
	 */
	void setName(String value);

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
	 * @see #setIndex(String)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskDependencyVariable_Index()
	 * @model required="true"
	 * @generated
	 */
	String getIndex();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.TaskDependencyVariable#getIndex <em>Index</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Index</em>' attribute.
	 * @see #getIndex()
	 * @generated
	 */
	void setIndex(String value);

} // TaskDependencyVariable
