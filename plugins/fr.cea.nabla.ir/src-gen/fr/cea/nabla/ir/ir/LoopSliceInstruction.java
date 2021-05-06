/**
 */
package fr.cea.nabla.ir.ir;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Loop Slice Instruction</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.LoopSliceInstruction#getIterationBlock <em>Iteration Block</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.LoopSliceInstruction#getTask <em>Task</em>}</li>
 * </ul>
 *
 * @see fr.cea.nabla.ir.ir.IrPackage#getLoopSliceInstruction()
 * @model
 * @generated
 */
public interface LoopSliceInstruction extends Instruction {
	/**
	 * Returns the value of the '<em><b>Iteration Block</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Iteration Block</em>' containment reference.
	 * @see #setIterationBlock(IterationBlock)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getLoopSliceInstruction_IterationBlock()
	 * @model containment="true" resolveProxies="true"
	 * @generated
	 */
	IterationBlock getIterationBlock();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.LoopSliceInstruction#getIterationBlock <em>Iteration Block</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Iteration Block</em>' containment reference.
	 * @see #getIterationBlock()
	 * @generated
	 */
	void setIterationBlock(IterationBlock value);

	/**
	 * Returns the value of the '<em><b>Task</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Task</em>' containment reference.
	 * @see #setTask(TaskInstruction)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getLoopSliceInstruction_Task()
	 * @model containment="true" resolveProxies="true"
	 * @generated
	 */
	TaskInstruction getTask();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.LoopSliceInstruction#getTask <em>Task</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Task</em>' containment reference.
	 * @see #getTask()
	 * @generated
	 */
	void setTask(TaskInstruction value);

} // LoopSliceInstruction
