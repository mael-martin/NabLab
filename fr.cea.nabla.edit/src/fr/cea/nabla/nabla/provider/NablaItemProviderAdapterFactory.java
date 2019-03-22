/**
 * generated by Xtext 2.15.0
 */
package fr.cea.nabla.nabla.provider;

import fr.cea.nabla.nabla.util.NablaAdapterFactory;

import java.util.ArrayList;
import java.util.Collection;

import org.eclipse.emf.common.notify.Adapter;
import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.Notifier;

import org.eclipse.emf.edit.provider.ChangeNotifier;
import org.eclipse.emf.edit.provider.ComposeableAdapterFactory;
import org.eclipse.emf.edit.provider.ComposedAdapterFactory;
import org.eclipse.emf.edit.provider.IChangeNotifier;
import org.eclipse.emf.edit.provider.IDisposable;
import org.eclipse.emf.edit.provider.IEditingDomainItemProvider;
import org.eclipse.emf.edit.provider.IItemLabelProvider;
import org.eclipse.emf.edit.provider.IItemPropertySource;
import org.eclipse.emf.edit.provider.INotifyChangedListener;
import org.eclipse.emf.edit.provider.IStructuredItemContentProvider;
import org.eclipse.emf.edit.provider.ITreeItemContentProvider;

/**
 * This is the factory that is used to provide the interfaces needed to support Viewers.
 * The adapters generated by this factory convert EMF adapter notifications into calls to {@link #fireNotifyChanged fireNotifyChanged}.
 * The adapters also support Eclipse property sheets.
 * Note that most of the adapters are shared among multiple instances.
 * <!-- begin-user-doc -->
 * <!-- end-user-doc -->
 * @generated
 */
public class NablaItemProviderAdapterFactory extends NablaAdapterFactory implements ComposeableAdapterFactory, IChangeNotifier, IDisposable {
	/**
	 * This keeps track of the root adapter factory that delegates to this adapter factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ComposedAdapterFactory parentAdapterFactory;

	/**
	 * This is used to implement {@link org.eclipse.emf.edit.provider.IChangeNotifier}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected IChangeNotifier changeNotifier = new ChangeNotifier();

	/**
	 * This keeps track of all the supported types checked by {@link #isFactoryForType isFactoryForType}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Collection<Object> supportedTypes = new ArrayList<Object>();

	/**
	 * This constructs an instance.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public NablaItemProviderAdapterFactory() {
		supportedTypes.add(IEditingDomainItemProvider.class);
		supportedTypes.add(IStructuredItemContentProvider.class);
		supportedTypes.add(ITreeItemContentProvider.class);
		supportedTypes.add(IItemLabelProvider.class);
		supportedTypes.add(IItemPropertySource.class);
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.NablaModule} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected NablaModuleItemProvider nablaModuleItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.NablaModule}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createNablaModuleAdapter() {
		if (nablaModuleItemProvider == null) {
			nablaModuleItemProvider = new NablaModuleItemProvider(this);
		}

		return nablaModuleItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Import} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ImportItemProvider importItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Import}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createImportAdapter() {
		if (importItemProvider == null) {
			importItemProvider = new ImportItemProvider(this);
		}

		return importItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.ItemType} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ItemTypeItemProvider itemTypeItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.ItemType}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createItemTypeAdapter() {
		if (itemTypeItemProvider == null) {
			itemTypeItemProvider = new ItemTypeItemProvider(this);
		}

		return itemTypeItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Job} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected JobItemProvider jobItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Job}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createJobAdapter() {
		if (jobItemProvider == null) {
			jobItemProvider = new JobItemProvider(this);
		}

		return jobItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Instruction} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected InstructionItemProvider instructionItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Instruction}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createInstructionAdapter() {
		if (instructionItemProvider == null) {
			instructionItemProvider = new InstructionItemProvider(this);
		}

		return instructionItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.SpaceIterator} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected SpaceIteratorItemProvider spaceIteratorItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.SpaceIterator}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createSpaceIteratorAdapter() {
		if (spaceIteratorItemProvider == null) {
			spaceIteratorItemProvider = new SpaceIteratorItemProvider(this);
		}

		return spaceIteratorItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.SpaceIteratorRange} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected SpaceIteratorRangeItemProvider spaceIteratorRangeItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.SpaceIteratorRange}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createSpaceIteratorRangeAdapter() {
		if (spaceIteratorRangeItemProvider == null) {
			spaceIteratorRangeItemProvider = new SpaceIteratorRangeItemProvider(this);
		}

		return spaceIteratorRangeItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.SpaceIteratorRef} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected SpaceIteratorRefItemProvider spaceIteratorRefItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.SpaceIteratorRef}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createSpaceIteratorRefAdapter() {
		if (spaceIteratorRefItemProvider == null) {
			spaceIteratorRefItemProvider = new SpaceIteratorRefItemProvider(this);
		}

		return spaceIteratorRefItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.ScalarVarDefinition} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ScalarVarDefinitionItemProvider scalarVarDefinitionItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.ScalarVarDefinition}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createScalarVarDefinitionAdapter() {
		if (scalarVarDefinitionItemProvider == null) {
			scalarVarDefinitionItemProvider = new ScalarVarDefinitionItemProvider(this);
		}

		return scalarVarDefinitionItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.VarGroupDeclaration} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected VarGroupDeclarationItemProvider varGroupDeclarationItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.VarGroupDeclaration}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createVarGroupDeclarationAdapter() {
		if (varGroupDeclarationItemProvider == null) {
			varGroupDeclarationItemProvider = new VarGroupDeclarationItemProvider(this);
		}

		return varGroupDeclarationItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Var} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected VarItemProvider varItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Var}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createVarAdapter() {
		if (varItemProvider == null) {
			varItemProvider = new VarItemProvider(this);
		}

		return varItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.ScalarVar} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ScalarVarItemProvider scalarVarItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.ScalarVar}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createScalarVarAdapter() {
		if (scalarVarItemProvider == null) {
			scalarVarItemProvider = new ScalarVarItemProvider(this);
		}

		return scalarVarItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.ArrayVar} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ArrayVarItemProvider arrayVarItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.ArrayVar}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createArrayVarAdapter() {
		if (arrayVarItemProvider == null) {
			arrayVarItemProvider = new ArrayVarItemProvider(this);
		}

		return arrayVarItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Connectivity} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ConnectivityItemProvider connectivityItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Connectivity}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createConnectivityAdapter() {
		if (connectivityItemProvider == null) {
			connectivityItemProvider = new ConnectivityItemProvider(this);
		}

		return connectivityItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.ItemArgType} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ItemArgTypeItemProvider itemArgTypeItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.ItemArgType}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createItemArgTypeAdapter() {
		if (itemArgTypeItemProvider == null) {
			itemArgTypeItemProvider = new ItemArgTypeItemProvider(this);
		}

		return itemArgTypeItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Function} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected FunctionItemProvider functionItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Function}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createFunctionAdapter() {
		if (functionItemProvider == null) {
			functionItemProvider = new FunctionItemProvider(this);
		}

		return functionItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.FunctionArg} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected FunctionArgItemProvider functionArgItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.FunctionArg}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createFunctionArgAdapter() {
		if (functionArgItemProvider == null) {
			functionArgItemProvider = new FunctionArgItemProvider(this);
		}

		return functionArgItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Reduction} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ReductionItemProvider reductionItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Reduction}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReductionAdapter() {
		if (reductionItemProvider == null) {
			reductionItemProvider = new ReductionItemProvider(this);
		}

		return reductionItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.ReductionArg} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ReductionArgItemProvider reductionArgItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.ReductionArg}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReductionArgAdapter() {
		if (reductionArgItemProvider == null) {
			reductionArgItemProvider = new ReductionArgItemProvider(this);
		}

		return reductionArgItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Expression} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ExpressionItemProvider expressionItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Expression}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createExpressionAdapter() {
		if (expressionItemProvider == null) {
			expressionItemProvider = new ExpressionItemProvider(this);
		}

		return expressionItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Real2Constant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Real2ConstantItemProvider real2ConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Real2Constant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReal2ConstantAdapter() {
		if (real2ConstantItemProvider == null) {
			real2ConstantItemProvider = new Real2ConstantItemProvider(this);
		}

		return real2ConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Real3Constant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Real3ConstantItemProvider real3ConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Real3Constant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReal3ConstantAdapter() {
		if (real3ConstantItemProvider == null) {
			real3ConstantItemProvider = new Real3ConstantItemProvider(this);
		}

		return real3ConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.VarRef} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected VarRefItemProvider varRefItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.VarRef}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createVarRefAdapter() {
		if (varRefItemProvider == null) {
			varRefItemProvider = new VarRefItemProvider(this);
		}

		return varRefItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.IteratorRangeOrRef} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected IteratorRangeOrRefItemProvider iteratorRangeOrRefItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.IteratorRangeOrRef}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createIteratorRangeOrRefAdapter() {
		if (iteratorRangeOrRefItemProvider == null) {
			iteratorRangeOrRefItemProvider = new IteratorRangeOrRefItemProvider(this);
		}

		return iteratorRangeOrRefItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.InstructionBlock} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected InstructionBlockItemProvider instructionBlockItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.InstructionBlock}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createInstructionBlockAdapter() {
		if (instructionBlockItemProvider == null) {
			instructionBlockItemProvider = new InstructionBlockItemProvider(this);
		}

		return instructionBlockItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Affectation} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected AffectationItemProvider affectationItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Affectation}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createAffectationAdapter() {
		if (affectationItemProvider == null) {
			affectationItemProvider = new AffectationItemProvider(this);
		}

		return affectationItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Loop} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected LoopItemProvider loopItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Loop}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createLoopAdapter() {
		if (loopItemProvider == null) {
			loopItemProvider = new LoopItemProvider(this);
		}

		return loopItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.If} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected IfItemProvider ifItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.If}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createIfAdapter() {
		if (ifItemProvider == null) {
			ifItemProvider = new IfItemProvider(this);
		}

		return ifItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Or} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected OrItemProvider orItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Or}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createOrAdapter() {
		if (orItemProvider == null) {
			orItemProvider = new OrItemProvider(this);
		}

		return orItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.And} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected AndItemProvider andItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.And}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createAndAdapter() {
		if (andItemProvider == null) {
			andItemProvider = new AndItemProvider(this);
		}

		return andItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Equality} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected EqualityItemProvider equalityItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Equality}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createEqualityAdapter() {
		if (equalityItemProvider == null) {
			equalityItemProvider = new EqualityItemProvider(this);
		}

		return equalityItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Comparison} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ComparisonItemProvider comparisonItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Comparison}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createComparisonAdapter() {
		if (comparisonItemProvider == null) {
			comparisonItemProvider = new ComparisonItemProvider(this);
		}

		return comparisonItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Plus} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected PlusItemProvider plusItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Plus}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createPlusAdapter() {
		if (plusItemProvider == null) {
			plusItemProvider = new PlusItemProvider(this);
		}

		return plusItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Minus} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected MinusItemProvider minusItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Minus}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createMinusAdapter() {
		if (minusItemProvider == null) {
			minusItemProvider = new MinusItemProvider(this);
		}

		return minusItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.MulOrDiv} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected MulOrDivItemProvider mulOrDivItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.MulOrDiv}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createMulOrDivAdapter() {
		if (mulOrDivItemProvider == null) {
			mulOrDivItemProvider = new MulOrDivItemProvider(this);
		}

		return mulOrDivItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Modulo} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ModuloItemProvider moduloItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Modulo}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createModuloAdapter() {
		if (moduloItemProvider == null) {
			moduloItemProvider = new ModuloItemProvider(this);
		}

		return moduloItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Parenthesis} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ParenthesisItemProvider parenthesisItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Parenthesis}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createParenthesisAdapter() {
		if (parenthesisItemProvider == null) {
			parenthesisItemProvider = new ParenthesisItemProvider(this);
		}

		return parenthesisItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.UnaryMinus} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected UnaryMinusItemProvider unaryMinusItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.UnaryMinus}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createUnaryMinusAdapter() {
		if (unaryMinusItemProvider == null) {
			unaryMinusItemProvider = new UnaryMinusItemProvider(this);
		}

		return unaryMinusItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Not} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected NotItemProvider notItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Not}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createNotAdapter() {
		if (notItemProvider == null) {
			notItemProvider = new NotItemProvider(this);
		}

		return notItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.IntConstant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected IntConstantItemProvider intConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.IntConstant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createIntConstantAdapter() {
		if (intConstantItemProvider == null) {
			intConstantItemProvider = new IntConstantItemProvider(this);
		}

		return intConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.RealConstant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected RealConstantItemProvider realConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.RealConstant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createRealConstantAdapter() {
		if (realConstantItemProvider == null) {
			realConstantItemProvider = new RealConstantItemProvider(this);
		}

		return realConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.BoolConstant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected BoolConstantItemProvider boolConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.BoolConstant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createBoolConstantAdapter() {
		if (boolConstantItemProvider == null) {
			boolConstantItemProvider = new BoolConstantItemProvider(this);
		}

		return boolConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Real2x2Constant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Real2x2ConstantItemProvider real2x2ConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Real2x2Constant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReal2x2ConstantAdapter() {
		if (real2x2ConstantItemProvider == null) {
			real2x2ConstantItemProvider = new Real2x2ConstantItemProvider(this);
		}

		return real2x2ConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.Real3x3Constant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Real3x3ConstantItemProvider real3x3ConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.Real3x3Constant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReal3x3ConstantAdapter() {
		if (real3x3ConstantItemProvider == null) {
			real3x3ConstantItemProvider = new Real3x3ConstantItemProvider(this);
		}

		return real3x3ConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.RealXCompactConstant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected RealXCompactConstantItemProvider realXCompactConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.RealXCompactConstant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createRealXCompactConstantAdapter() {
		if (realXCompactConstantItemProvider == null) {
			realXCompactConstantItemProvider = new RealXCompactConstantItemProvider(this);
		}

		return realXCompactConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.MinConstant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected MinConstantItemProvider minConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.MinConstant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createMinConstantAdapter() {
		if (minConstantItemProvider == null) {
			minConstantItemProvider = new MinConstantItemProvider(this);
		}

		return minConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.MaxConstant} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected MaxConstantItemProvider maxConstantItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.MaxConstant}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createMaxConstantAdapter() {
		if (maxConstantItemProvider == null) {
			maxConstantItemProvider = new MaxConstantItemProvider(this);
		}

		return maxConstantItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.FunctionCall} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected FunctionCallItemProvider functionCallItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.FunctionCall}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createFunctionCallAdapter() {
		if (functionCallItemProvider == null) {
			functionCallItemProvider = new FunctionCallItemProvider(this);
		}

		return functionCallItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nabla.ReductionCall} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ReductionCallItemProvider reductionCallItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nabla.ReductionCall}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReductionCallAdapter() {
		if (reductionCallItemProvider == null) {
			reductionCallItemProvider = new ReductionCallItemProvider(this);
		}

		return reductionCallItemProvider;
	}

	/**
	 * This returns the root adapter factory that contains this factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public ComposeableAdapterFactory getRootAdapterFactory() {
		return parentAdapterFactory == null ? this : parentAdapterFactory.getRootAdapterFactory();
	}

	/**
	 * This sets the composed adapter factory that contains this factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void setParentAdapterFactory(ComposedAdapterFactory parentAdapterFactory) {
		this.parentAdapterFactory = parentAdapterFactory;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean isFactoryForType(Object type) {
		return supportedTypes.contains(type) || super.isFactoryForType(type);
	}

	/**
	 * This implementation substitutes the factory itself as the key for the adapter.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter adapt(Notifier notifier, Object type) {
		return super.adapt(notifier, this);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object adapt(Object object, Object type) {
		if (isFactoryForType(type)) {
			Object adapter = super.adapt(object, type);
			if (!(type instanceof Class<?>) || (((Class<?>)type).isInstance(adapter))) {
				return adapter;
			}
		}

		return null;
	}

	/**
	 * This adds a listener.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void addListener(INotifyChangedListener notifyChangedListener) {
		changeNotifier.addListener(notifyChangedListener);
	}

	/**
	 * This removes a listener.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void removeListener(INotifyChangedListener notifyChangedListener) {
		changeNotifier.removeListener(notifyChangedListener);
	}

	/**
	 * This delegates to {@link #changeNotifier} and to {@link #parentAdapterFactory}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void fireNotifyChanged(Notification notification) {
		changeNotifier.fireNotifyChanged(notification);

		if (parentAdapterFactory != null) {
			parentAdapterFactory.fireNotifyChanged(notification);
		}
	}

	/**
	 * This disposes all of the item providers created by this factory. 
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void dispose() {
		if (nablaModuleItemProvider != null) nablaModuleItemProvider.dispose();
		if (importItemProvider != null) importItemProvider.dispose();
		if (itemTypeItemProvider != null) itemTypeItemProvider.dispose();
		if (jobItemProvider != null) jobItemProvider.dispose();
		if (instructionItemProvider != null) instructionItemProvider.dispose();
		if (spaceIteratorItemProvider != null) spaceIteratorItemProvider.dispose();
		if (spaceIteratorRangeItemProvider != null) spaceIteratorRangeItemProvider.dispose();
		if (spaceIteratorRefItemProvider != null) spaceIteratorRefItemProvider.dispose();
		if (scalarVarDefinitionItemProvider != null) scalarVarDefinitionItemProvider.dispose();
		if (varGroupDeclarationItemProvider != null) varGroupDeclarationItemProvider.dispose();
		if (varItemProvider != null) varItemProvider.dispose();
		if (scalarVarItemProvider != null) scalarVarItemProvider.dispose();
		if (arrayVarItemProvider != null) arrayVarItemProvider.dispose();
		if (connectivityItemProvider != null) connectivityItemProvider.dispose();
		if (itemArgTypeItemProvider != null) itemArgTypeItemProvider.dispose();
		if (functionItemProvider != null) functionItemProvider.dispose();
		if (functionArgItemProvider != null) functionArgItemProvider.dispose();
		if (reductionItemProvider != null) reductionItemProvider.dispose();
		if (reductionArgItemProvider != null) reductionArgItemProvider.dispose();
		if (expressionItemProvider != null) expressionItemProvider.dispose();
		if (real2ConstantItemProvider != null) real2ConstantItemProvider.dispose();
		if (real3ConstantItemProvider != null) real3ConstantItemProvider.dispose();
		if (varRefItemProvider != null) varRefItemProvider.dispose();
		if (iteratorRangeOrRefItemProvider != null) iteratorRangeOrRefItemProvider.dispose();
		if (instructionBlockItemProvider != null) instructionBlockItemProvider.dispose();
		if (affectationItemProvider != null) affectationItemProvider.dispose();
		if (loopItemProvider != null) loopItemProvider.dispose();
		if (ifItemProvider != null) ifItemProvider.dispose();
		if (orItemProvider != null) orItemProvider.dispose();
		if (andItemProvider != null) andItemProvider.dispose();
		if (equalityItemProvider != null) equalityItemProvider.dispose();
		if (comparisonItemProvider != null) comparisonItemProvider.dispose();
		if (plusItemProvider != null) plusItemProvider.dispose();
		if (minusItemProvider != null) minusItemProvider.dispose();
		if (mulOrDivItemProvider != null) mulOrDivItemProvider.dispose();
		if (moduloItemProvider != null) moduloItemProvider.dispose();
		if (parenthesisItemProvider != null) parenthesisItemProvider.dispose();
		if (unaryMinusItemProvider != null) unaryMinusItemProvider.dispose();
		if (notItemProvider != null) notItemProvider.dispose();
		if (intConstantItemProvider != null) intConstantItemProvider.dispose();
		if (realConstantItemProvider != null) realConstantItemProvider.dispose();
		if (boolConstantItemProvider != null) boolConstantItemProvider.dispose();
		if (real2x2ConstantItemProvider != null) real2x2ConstantItemProvider.dispose();
		if (real3x3ConstantItemProvider != null) real3x3ConstantItemProvider.dispose();
		if (realXCompactConstantItemProvider != null) realXCompactConstantItemProvider.dispose();
		if (minConstantItemProvider != null) minConstantItemProvider.dispose();
		if (maxConstantItemProvider != null) maxConstantItemProvider.dispose();
		if (functionCallItemProvider != null) functionCallItemProvider.dispose();
		if (reductionCallItemProvider != null) reductionCallItemProvider.dispose();
	}

}
