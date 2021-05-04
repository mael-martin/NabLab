/**
 */
package fr.cea.nabla.ir.ir.impl;

import fr.cea.nabla.ir.ir.Instruction;
import fr.cea.nabla.ir.ir.IrPackage;
import fr.cea.nabla.ir.ir.TaskDependencyVariable;
import fr.cea.nabla.ir.ir.TaskInstruction;

import java.util.Collection;
import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;

import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.util.EObjectContainmentEList;
import org.eclipse.emf.ecore.util.InternalEList;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Task Instruction</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.TaskInstructionImpl#getContent <em>Content</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.TaskInstructionImpl#getInVars <em>In Vars</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.TaskInstructionImpl#getOutVars <em>Out Vars</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.impl.TaskInstructionImpl#getMinimalInVars <em>Minimal In Vars</em>}</li>
 * </ul>
 *
 * @generated
 */
public class TaskInstructionImpl extends InstructionImpl implements TaskInstruction {
	/**
	 * The cached value of the '{@link #getContent() <em>Content</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getContent()
	 * @generated
	 * @ordered
	 */
	protected Instruction content;

	/**
	 * The cached value of the '{@link #getInVars() <em>In Vars</em>}' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getInVars()
	 * @generated
	 * @ordered
	 */
	protected EList<TaskDependencyVariable> inVars;
	/**
	 * The cached value of the '{@link #getOutVars() <em>Out Vars</em>}' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getOutVars()
	 * @generated
	 * @ordered
	 */
	protected EList<TaskDependencyVariable> outVars;
	/**
	 * The cached value of the '{@link #getMinimalInVars() <em>Minimal In Vars</em>}' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getMinimalInVars()
	 * @generated
	 * @ordered
	 */
	protected EList<TaskDependencyVariable> minimalInVars;

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected TaskInstructionImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return IrPackage.Literals.TASK_INSTRUCTION;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Instruction getContent() {
		return content;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public NotificationChain basicSetContent(Instruction newContent, NotificationChain msgs) {
		Instruction oldContent = content;
		content = newContent;
		if (eNotificationRequired()) {
			ENotificationImpl notification = new ENotificationImpl(this, Notification.SET, IrPackage.TASK_INSTRUCTION__CONTENT, oldContent, newContent);
			if (msgs == null) msgs = notification; else msgs.add(notification);
		}
		return msgs;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setContent(Instruction newContent) {
		if (newContent != content) {
			NotificationChain msgs = null;
			if (content != null)
				msgs = ((InternalEObject)content).eInverseRemove(this, EOPPOSITE_FEATURE_BASE - IrPackage.TASK_INSTRUCTION__CONTENT, null, msgs);
			if (newContent != null)
				msgs = ((InternalEObject)newContent).eInverseAdd(this, EOPPOSITE_FEATURE_BASE - IrPackage.TASK_INSTRUCTION__CONTENT, null, msgs);
			msgs = basicSetContent(newContent, msgs);
			if (msgs != null) msgs.dispatch();
		}
		else if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, IrPackage.TASK_INSTRUCTION__CONTENT, newContent, newContent));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EList<TaskDependencyVariable> getInVars() {
		if (inVars == null) {
			inVars = new EObjectContainmentEList<TaskDependencyVariable>(TaskDependencyVariable.class, this, IrPackage.TASK_INSTRUCTION__IN_VARS);
		}
		return inVars;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EList<TaskDependencyVariable> getOutVars() {
		if (outVars == null) {
			outVars = new EObjectContainmentEList<TaskDependencyVariable>(TaskDependencyVariable.class, this, IrPackage.TASK_INSTRUCTION__OUT_VARS);
		}
		return outVars;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EList<TaskDependencyVariable> getMinimalInVars() {
		if (minimalInVars == null) {
			minimalInVars = new EObjectContainmentEList<TaskDependencyVariable>(TaskDependencyVariable.class, this, IrPackage.TASK_INSTRUCTION__MINIMAL_IN_VARS);
		}
		return minimalInVars;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
			case IrPackage.TASK_INSTRUCTION__CONTENT:
				return basicSetContent(null, msgs);
			case IrPackage.TASK_INSTRUCTION__IN_VARS:
				return ((InternalEList<?>)getInVars()).basicRemove(otherEnd, msgs);
			case IrPackage.TASK_INSTRUCTION__OUT_VARS:
				return ((InternalEList<?>)getOutVars()).basicRemove(otherEnd, msgs);
			case IrPackage.TASK_INSTRUCTION__MINIMAL_IN_VARS:
				return ((InternalEList<?>)getMinimalInVars()).basicRemove(otherEnd, msgs);
		}
		return super.eInverseRemove(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case IrPackage.TASK_INSTRUCTION__CONTENT:
				return getContent();
			case IrPackage.TASK_INSTRUCTION__IN_VARS:
				return getInVars();
			case IrPackage.TASK_INSTRUCTION__OUT_VARS:
				return getOutVars();
			case IrPackage.TASK_INSTRUCTION__MINIMAL_IN_VARS:
				return getMinimalInVars();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@SuppressWarnings("unchecked")
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case IrPackage.TASK_INSTRUCTION__CONTENT:
				setContent((Instruction)newValue);
				return;
			case IrPackage.TASK_INSTRUCTION__IN_VARS:
				getInVars().clear();
				getInVars().addAll((Collection<? extends TaskDependencyVariable>)newValue);
				return;
			case IrPackage.TASK_INSTRUCTION__OUT_VARS:
				getOutVars().clear();
				getOutVars().addAll((Collection<? extends TaskDependencyVariable>)newValue);
				return;
			case IrPackage.TASK_INSTRUCTION__MINIMAL_IN_VARS:
				getMinimalInVars().clear();
				getMinimalInVars().addAll((Collection<? extends TaskDependencyVariable>)newValue);
				return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case IrPackage.TASK_INSTRUCTION__CONTENT:
				setContent((Instruction)null);
				return;
			case IrPackage.TASK_INSTRUCTION__IN_VARS:
				getInVars().clear();
				return;
			case IrPackage.TASK_INSTRUCTION__OUT_VARS:
				getOutVars().clear();
				return;
			case IrPackage.TASK_INSTRUCTION__MINIMAL_IN_VARS:
				getMinimalInVars().clear();
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case IrPackage.TASK_INSTRUCTION__CONTENT:
				return content != null;
			case IrPackage.TASK_INSTRUCTION__IN_VARS:
				return inVars != null && !inVars.isEmpty();
			case IrPackage.TASK_INSTRUCTION__OUT_VARS:
				return outVars != null && !outVars.isEmpty();
			case IrPackage.TASK_INSTRUCTION__MINIMAL_IN_VARS:
				return minimalInVars != null && !minimalInVars.isEmpty();
		}
		return super.eIsSet(featureID);
	}

} //TaskInstructionImpl
